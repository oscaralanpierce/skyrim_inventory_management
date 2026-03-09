# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Weapon, type: :model do
  describe 'validations' do
    subject(:validate) { weapon.validate }

    let(:weapon) { build(:weapon) }

    it 'is invalid without a name' do
      weapon.name = nil
      validate
      expect(weapon.errors[:name]).to include "can't be blank"
    end

    it 'is invalid with an invalid category name' do
      weapon.category = 'foo'
      validate
      expect(weapon.errors[:category]).to include 'must be "one-handed", "two-handed", or "archery"'
    end

    it 'is invalid with an invalid weapon type' do
      weapon.weapon_type = 'foo'
      validate
      expect(weapon.errors[:weapon_type]).to include 'must be a valid type of weapon that occurs in Skyrim'
    end

    it 'is invalid with a negative unit weight' do
      weapon.unit_weight = -0.5
      validate
      expect(weapon.errors[:unit_weight]).to include 'must be greater than or equal to 0'
    end

    describe 'canonical weapon validations' do
      let(:weapon) { build(:weapon, canonical_weapon:, game:) }
      let(:game) { create(:game) }

      context 'when the canonical weapon is not unique' do
        let(:canonical_weapon) { create(:canonical_weapon) }

        before { create_list(:weapon, 3, canonical_weapon:, game:) }

        it 'is valid' do
          expect(weapon).to be_valid
        end
      end

      context 'when the canonical weapon is unique' do
        let(:canonical_weapon) { create(:canonical_weapon, max_quantity: 1, unique_item: true, rare_item: true) }

        context 'when there are no other matches for the canonical weapon' do
          it 'is valid' do
            expect(weapon).to be_valid
          end
        end

        context 'when the canonical weapon has other matches in other games' do
          before { create(:weapon, canonical_weapon:) }

          it 'is valid' do
            expect(weapon).to be_valid
          end
        end

        context 'when the canonical weapon has other matches in the same game' do
          before { create(:weapon, canonical_weapon:, game:) }

          it 'is invalid' do
            validate
            expect(weapon.errors[:base]).to include 'is a duplicate of a unique in-game item'
          end
        end
      end
    end
  end

  describe '#canonical_model' do
    subject(:canonical_model) { weapon.canonical_model }

    context 'when there is a canonical weapon associated' do
      let(:weapon) { create(:weapon, :with_matching_canonical) }

      it 'returns the canonical weapon' do
        expect(canonical_model).to eq weapon.canonical_weapon
      end
    end

    context 'when there is no canonical weapon associated' do
      let(:weapon) { create(:weapon) }

      before { create_list(:canonical_weapon, 2) }

      it 'returns nil' do
        expect(canonical_model).to be_nil
      end
    end
  end

  describe '#canonical_models' do
    subject(:canonical_models) { weapon.canonical_models }

    context 'when there is no existing canonical match' do
      before { create(:canonical_weapon, name: 'Something Else') }

      context 'when only the name has to match' do
        let(:weapon) { build(:weapon, unit_weight: nil) }

        let!(:matching_canonicals) { create_list(:canonical_weapon, 3, unit_weight: 2.5) }

        it 'returns all matching items' do
          expect(canonical_models).to contain_exactly(*matching_canonicals)
        end
      end

      context 'when multiple attributes have to match' do
        let(:weapon) { build(:weapon, unit_weight: 2.5) }

        let!(:matching_canonicals) { create_list(:canonical_weapon, 3, unit_weight: 2.5) }

        before { create(:canonical_weapon, unit_weight: 1) }

        it 'returns only the items for which all values match' do
          expect(canonical_models).to contain_exactly(*matching_canonicals)
        end
      end

      context 'when there are enchantments' do
        let(:weapon) { create(:weapon) }
        let(:shared_enchantment) { create(:enchantment) }

        let!(:matching_canonicals) { create_list(:canonical_weapon, 2, enchantable: false) }

        before do
          create(:enchantables_enchantment, enchantable: matching_canonicals.first, enchantment: shared_enchantment)

          create(:enchantables_enchantment, enchantable: matching_canonicals.last, enchantment: shared_enchantment)

          create(:enchantables_enchantment, enchantable: matching_canonicals.first)
          create(:enchantables_enchantment, enchantable: matching_canonicals.last)

          matching_canonicals.each {|canonical| canonical.enchantables_enchantments.reload }

          create(:enchantables_enchantment, enchantable: weapon, enchantment: shared_enchantment, added_automatically: false)

          create(:enchantables_enchantment, enchantable: weapon, enchantment: matching_canonicals.first.enchantments.last, added_automatically: true)

          weapon.enchantables_enchantments.reload
        end

        it 'matches based only on manually added enchantments' do
          expect(canonical_models).to contain_exactly(*matching_canonicals)
        end
      end
    end

    context 'when changed attributes lead to a changed canonical' do
      let(:weapon) { create(:weapon, :with_matching_canonical) }

      let!(:new_canonical) { create(:canonical_weapon, name: 'Nordic Carved Sword', unit_weight: 9) }

      it 'returns the new canonical' do
        weapon.name = 'Nordic Carved Sword'
        weapon.unit_weight = 9

        expect(canonical_models).to contain_exactly(new_canonical)
      end
    end
  end

  describe '::before_validation' do
    subject(:validate) { weapon.validate }

    context 'when there is a single matching canonical model' do
      context 'when the in-game item model has no enchantments' do
        let(:weapon) { build(:weapon, name: 'foobar', unit_weight: 12) }

        let!(:matching_canonical) { create(:canonical_weapon, :with_enchantments, name: 'Foobar', unit_weight: 12) }

        before { create(:canonical_weapon, name: 'Foobar', unit_weight: 14) }

        it 'assigns the canonical_weapon' do
          expect { validate }
            .to change(weapon, :canonical_weapon)
                  .from(nil)
                  .to(matching_canonical)
        end

        it 'sets values on the weapon model', :aggregate_failures do
          validate
          expect(weapon.name).to eq matching_canonical.name
          expect(weapon.category).to eq matching_canonical.category
          expect(weapon.weapon_type).to eq matching_canonical.weapon_type
          expect(weapon.unit_weight).to eq matching_canonical.unit_weight
          expect(weapon.magical_effects).to eq matching_canonical.magical_effects
        end

        it "doesn't set enchantments" do
          validate
          expect(weapon.enchantments).to be_empty
        end
      end

      context 'when the in-game item has enchantments' do
        let(:weapon) { create(:weapon, name: 'foobar') }

        let!(:canonicals) { [create(:canonical_weapon, :with_enchantments, name: 'Foobar'), create(:canonical_weapon, name: 'Foobar', enchantable: false), create(:canonical_weapon, name: 'Foobar', enchantable: false)] }

        before do
          # Returning to this context, I'm realising it is difficult to reason about.
          # Here, if the second canonical matches the enchantment on the first
          # canonical perfectly, both will be matched even though the second one is
          # not enchantable. This is possible because non-enchantable canonicals
          # can, in many cases, have existing enchantments, and those are allowed -
          # indeed, required - to be present on matching in-game items.
          create(:enchantables_enchantment, enchantable: canonicals.second, enchantment: canonicals.first.enchantments.first, strength: 2)

          create(:enchantables_enchantment, enchantable: weapon, enchantment: canonicals.first.enchantments.first, strength: canonicals.first.enchantments.first.strength)

          weapon.enchantables_enchantments.reload
        end

        it 'assigns the canonical_weapon' do
          validate
          expect(weapon.canonical_weapon).to eq canonicals.first
        end

        it 'sets values on the weapon model', :aggregate_failures do
          validate
          expect(weapon.name).to eq canonicals.first.name
          expect(weapon.category).to eq canonicals.first.category
          expect(weapon.weapon_type).to eq canonicals.first.weapon_type
          expect(weapon.unit_weight).to eq canonicals.first.unit_weight
          expect(weapon.magical_effects).to eq canonicals.first.magical_effects
        end
      end
    end

    context 'when there are multiple matching canonical models' do
      context 'when there are no enchantments involved' do
        let(:weapon) { build(:weapon, name: 'foobar') }

        before { create_list(:canonical_weapon, 2, name: 'Foobar') }

        it "doesn't assign a canonical_weapon" do
          validate
          expect(weapon.canonical_weapon).to be_nil
        end

        it "doesn't set values", :aggregate_failures do
          validate
          expect(weapon.name).to eq 'foobar'
          expect(weapon.category).to be_nil
          expect(weapon.weapon_type).to be_nil
          expect(weapon.unit_weight).to be_nil
          expect(weapon.magical_effects).to be_nil
        end
      end

      context 'when there are enchantments' do
        context 'when the in-game item model has no enchantments' do
          let(:weapon) { build(:weapon, name: 'foobar') }

          before do
            create(:canonical_weapon, :with_enchantments, name: 'Foobar')
            create(:canonical_weapon, name: 'Foobar')
          end

          it "doesn't assign a canonical_weapon" do
            validate
            expect(weapon.canonical_weapon).to be_nil
          end

          it "doesn't set values", :aggregate_failures do
            validate
            expect(weapon.name).to eq 'foobar'
            expect(weapon.category).to be_nil
            expect(weapon.weapon_type).to be_nil
            expect(weapon.unit_weight).to be_nil
            expect(weapon.magical_effects).to be_nil
          end

          it "doesn't set enchantments" do
            validate
            expect(weapon.enchantments).to be_empty
          end

          it "doesn't set errors" do
            validate
            expect(weapon.errors[:base]).to be_empty
          end
        end

        context 'when the in-game item model is already enchanted' do
          let(:weapon) { create(:weapon, name: 'foobar') }

          let!(:canonicals) { [create(:canonical_weapon, :with_enchantments, name: 'Foobar', enchantable: false), create(:canonical_weapon, :with_enchantments, name: 'FoObAr', enchantable: false), create(:canonical_weapon, :with_enchantments, name: 'fOoBaR', enchantable: false), create(:canonical_weapon, name: 'fOObAR', enchantable: true)] }

          before { create(:enchantables_enchantment, enchantable: weapon, enchantment: canonicals.first.enchantments.first, strength: canonicals.first.enchantments.first.strength) }

          it "doesn't assign a canonical_weapon" do
            validate
            expect(weapon.canonical_weapon).to be_nil
          end

          it "doesn't set values", :aggregate_failures do
            validate
            expect(weapon.name).to eq 'foobar'
            expect(weapon.category).to be_nil
            expect(weapon.weapon_type).to be_nil
            expect(weapon.unit_weight).to be_nil
            expect(weapon.magical_effects).to be_nil
          end

          it "doesn't set enchantments" do
            expect { validate }
              .not_to change(weapon.enchantments, :length)
          end

          it "doesn't set errors" do
            validate
            expect(weapon.errors[:base]).to be_empty
          end
        end
      end
    end

    context 'when there are no matching canonical models' do
      let(:weapon) { build(:weapon, name: 'Foobar') }

      before { create_list(:canonical_weapon, 2) }

      it 'adds an error' do
        validate
        expect(weapon.errors[:base]).to include "doesn't match any item that exists in Skyrim"
      end
    end

    context 'when updating in-game item attributes' do
      let(:weapon) { create(:weapon, :with_enchanted_canonical) }

      before do
        weapon.canonical_weapon.update!(enchantable: true)

        create(:enchantables_enchantment, enchantable: weapon, added_automatically: false)

        weapon.enchantables_enchantments.reload
      end

      context 'when the update changes the canonical association' do
        let!(:new_canonical) { create(:canonical_weapon, name: 'Elven Battleaxe of Shocks', unit_weight: 24, weapon_type: 'battleaxe', category: 'two-handed') }

        before do
          create(:enchantables_enchantment, enchantable: new_canonical, enchantment: weapon.enchantables_enchantments.added_manually.first.enchantment)

          new_canonical.enchantables_enchantments.reload
        end

        it 'updates the canonical association' do
          weapon.name = 'elven battleaxe of shocks'
          weapon.unit_weight = nil
          weapon.weapon_type = nil
          weapon.category = nil

          expect { validate }
            .to change(weapon, :canonical_weapon)
                  .to(new_canonical)
        end

        it 'updates attributes', :aggregate_failures do
          weapon.name = 'elven battleaxe of shocks'
          weapon.unit_weight = nil
          weapon.weapon_type = nil
          weapon.category = nil

          validate

          expect(weapon.name).to eq 'Elven Battleaxe of Shocks'
          expect(weapon.unit_weight).to eq 24
          expect(weapon.weapon_type).to eq 'battleaxe'
          expect(weapon.category).to eq 'two-handed'
        end

        it 'removes automatically added enchantments', :aggregate_failures do
          weapon.name = 'elven battleaxe of shocks'
          weapon.unit_weight = nil
          weapon.weapon_type = nil
          weapon.category = nil

          validate
          weapon.enchantables_enchantments.reload

          expect(weapon.enchantables_enchantments.count).to eq 1
          expect(weapon.enchantables_enchantments.pluck(:added_automatically)).to be_all(false)
        end
      end

      context 'when the update results in an ambiguous match' do
        before { create_list(:canonical_weapon, 2, name: 'Iron Mace of Burning') }

        it 'removes the associated canonical weapon' do
          weapon.name = 'iron mace of burning'

          expect { validate }
            .to change(weapon, :canonical_weapon)
                  .to(nil)
        end

        it "doesn't update attributes" do
          weapon.name = 'iron mace of burning'

          validate

          expect(weapon.name).to eq 'iron mace of burning'
        end

        it 'removes automatically-added enchantments', :aggregate_failures do
          weapon.name = 'iron mace of burning'

          validate
          weapon.enchantables_enchantments.reload

          expect(weapon.enchantables_enchantments.count).to eq 1
          expect(weapon.enchantables_enchantments.pluck(:added_automatically)).to be_all(false)
        end
      end

      context 'when the update results in no canonical matches' do
        it 'sets the canonical weapon to nil' do
          weapon.name = 'Orcish Greatsword of Debilitation'

          expect { validate }
            .to change(weapon, :canonical_weapon)
                  .to(nil)
        end

        it 'removes automatically-added enchantments', :aggregate_failures do
          weapon.name = 'Orcish Greatsword of Debilitation'

          validate
          weapon.enchantables_enchantments.reload

          expect(weapon.enchantables_enchantments.count).to eq 1
          expect(weapon.enchantables_enchantments.pluck(:added_automatically)).to be_all(false)
        end
      end
    end
  end

  describe '::after_save' do
    context 'when there is one matching canonical model' do
      let!(:matching_canonical) { create(:canonical_weapon, :with_enchantments, name: 'Elven War Axe') }

      context "when the new weapon doesn't have its own enchantments" do
        let(:weapon) { build(:weapon, name: 'elven war axe') }

        it 'adds enchantments from the canonical weapon' do
          weapon.save!
          expect(weapon.enchantments.length).to eq 2
        end

        it 'sets "added_automatically" to true on new associations' do
          weapon.save!

          expect(weapon.enchantables_enchantments.pluck(:added_automatically)).to be_all(true)
        end

        it 'sets the correct strengths', :aggregate_failures do
          weapon.save!
          matching_canonical.enchantables_enchantments.each do |join_model|
            has_matching = weapon.enchantables_enchantments.any? {|model| model.enchantment == join_model.enchantment && model.strength == join_model.strength }

            expect(has_matching).to be true
          end
        end
      end

      context 'when the new weapon has its own enchantments' do
        let(:weapon) { create(:weapon, :with_enchantments, name: 'elven war axe') }

        it "doesn't remove the existing enchantments" do
          expect(weapon.enchantments.reload.length).to eq 4
        end

        it 'sets "added_automatically" only on the new associations' do
          expect(weapon.enchantables_enchantments.pluck(:added_automatically)).to eq [true, true, false, false]
        end
      end
    end

    context 'when there are multiple canonical models' do
      subject(:save) { weapon.save! }

      let(:weapon) { build(:weapon, name: 'Foobar') }

      before { create_list(:canonical_weapon, 2, :with_enchantments, name: 'Foobar') }

      it "doesn't add enchantments" do
        expect { save }
          .not_to change(weapon.enchantables_enchantments.reload, :length)
      end
    end
  end

  describe 'delegated methods' do
    describe '#crafting_materials' do
      subject(:crafting_materials) { weapon.crafting_materials }

      context 'when there is a canonical weapon assigned' do
        let(:weapon) { create(:weapon, name: 'Foobar', canonical_weapon:) }
        let(:canonical_weapon) { create(:canonical_weapon, :with_crafting_materials, name: 'Foobar') }

        it 'returns the crafting materials for the canonical' do
          expect(crafting_materials).to eq canonical_weapon.crafting_materials
        end
      end

      context 'when there is no canonical weapon assigned' do
        let(:weapon) { create(:weapon, name: 'Foobar') }

        before { create_list(:canonical_weapon, 2, name: 'Foobar') }

        it 'returns nil' do
          expect(crafting_materials).to be_nil
        end
      end
    end

    describe '#tempering_materials' do
      subject(:tempering_materials) { weapon.tempering_materials }

      context 'when there is a canonical weapon assigned' do
        let(:weapon) { create(:weapon, name: 'Foobar', canonical_weapon:) }
        let(:canonical_weapon) { create(:canonical_weapon, :with_tempering_materials, name: 'Foobar') }

        it 'returns the tempering materials for the canonical' do
          expect(tempering_materials).to eq canonical_weapon.tempering_materials
        end
      end

      context 'when there is no canonical weapon assigned' do
        let(:weapon) { create(:weapon, name: 'Foobar') }

        before { create_list(:canonical_weapon, 2, name: 'Foobar') }

        it 'returns nil' do
          expect(tempering_materials).to be_nil
        end
      end
    end
  end

  describe 'adding enchantments' do
    let(:weapon) { create(:weapon, name: 'foobar') }

    before { create_list(:canonical_weapon, 2, :with_enchantments, name: 'Foobar', enchantable:) }

    context 'when the added enchantment eliminates all canoncial matches' do
      subject(:add_enchantment) { create(:enchantables_enchantment, enchantable: weapon) }

      let(:enchantable) { false }

      it "doesn't allow the enchantment to be added", :aggregate_failures do
        expect { add_enchantment }
          .to raise_error(ActiveRecord::RecordInvalid)

        expect(weapon.enchantments.reload.length).to eq 0
      end
    end

    context 'when the added enchantment narrows it down to one canonical match' do
      subject(:add_enchantment) { create(:enchantables_enchantment, enchantable: weapon, enchantment: Canonical::Weapon.last.enchantments.first, strength: Canonical::Weapon.last.enchantments.first.strength) }

      let(:enchantable) { false }

      it 'sets the canonical weapon' do
        expect { add_enchantment }
          .to change(weapon.reload, :canonical_weapon)
                .from(nil)
                .to(Canonical::Weapon.last)
      end

      it 'adds missing enchantments' do
        add_enchantment
        expect(weapon.enchantments.reload.length).to eq 2
      end
    end

    context 'when there are still multiple canonicals after adding the enchantment' do
      subject(:add_enchantment) { create(:enchantables_enchantment, enchantable: weapon) }

      let(:enchantable) { true }

      it "doesn't assign a canonical weapon" do
        expect { add_enchantment }
          .not_to change(weapon.reload, :canonical_weapon)
      end

      it "doesn't add additional enchantments" do
        add_enchantment
        expect(weapon.enchantments.reload.length).to eq 1
      end
    end
  end
end

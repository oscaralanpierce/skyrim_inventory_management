# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Armor, type: :model do
  describe 'validations' do
    subject(:validate) { armor.validate }

    let(:armor) { build(:armor) }

    it 'is invalid without a name' do
      armor.name = nil
      validate
      expect(armor.errors[:name]).to include "can't be blank"
    end

    it 'is invalid with an invalid weight value' do
      armor.weight = 'medium armor'
      validate
      expect(armor.errors[:weight]).to include 'must be "light armor" or "heavy armor"'
    end

    it 'is invalid with a negative unit weight' do
      armor.unit_weight = -2.5
      validate
      expect(armor.errors[:unit_weight]).to include 'must be greater than or equal to 0'
    end

    describe '#canonical_armor' do
      context 'when the canonical armor is not a unique item' do
        let(:canonical_armor) { create(:canonical_armor, unique_item: false) }

        before { create(:armor, canonical_armor:) }

        it 'is allowed' do
          armor.canonical_armor = canonical_armor
          validate
          expect(armor.errors[:base]).to be_empty
        end
      end

      context 'when the canonical armor is a unique item' do
        let(:canonical_armor) { create(:canonical_armor, max_quantity: 1, unique_item: true, rare_item: true) }

        context 'when there are duplicate associations in the same game' do
          let(:game) { create(:game) }

          before { create(:armor, canonical_armor:, game:) }

          it 'is invalid' do
            armor.canonical_armor = canonical_armor
            armor.game = game
            validate
            expect(armor.errors[:base]).to include 'is a duplicate of a unique in-game item'
          end
        end

        context 'when there are duplicate associations for different games' do
          before { create(:armor, canonical_armor:) }

          it 'is invalid' do
            armor.canonical_armor = canonical_armor
            validate
            expect(armor.errors[:base]).to be_empty
          end
        end
      end
    end
  end

  describe 'delegated methods' do
    let!(:canonical_armor) { create(:canonical_armor, name: 'Steel Plate Armor') }
    let(:armor) { create(:armor, name: 'Steel Plate Armor', canonical_armor:) }

    before do
      3.times {|n| create(:canonical_material, craftable: canonical_armor, quantity: n + 1) }

      create(:canonical_material, source_material: create(:canonical_raw_material), temperable: canonical_armor)

      canonical_armor.reload
    end

    describe '#crafting_materials' do
      it 'uses the values from the canonical model' do
        expect(armor.crafting_materials).to eq canonical_armor.crafting_materials
      end
    end

    describe '#tempering_materials' do
      it 'uses the values from the canonical model' do
        expect(armor.tempering_materials).to eq canonical_armor.tempering_materials
      end
    end

    context 'when there is no canonical model' do
      let(:armor) { build(:armor, canonical_armor: nil) }

      it 'returns a nil value for crafting_materials' do
        expect(armor.crafting_materials).to be_nil
      end

      it 'returns a nil value for tempering_materials' do
        expect(armor.tempering_materials).to be_nil
      end
    end
  end

  describe '::before_validation' do
    subject(:validate) { armor.validate }

    context 'when there is a single matching canonical model' do
      let(:armor) { build(:armor, name: 'steel plate armor', unit_weight: 20, magical_effects: 'something') }

      let!(:matching_canonical) { create(:canonical_armor, :with_enchantments, name: 'Steel Plate Armor', unit_weight: 20, magical_effects: 'Something', weight: 'heavy armor') }

      before { create(:canonical_armor, name: 'Steel Plate Armor', unit_weight: 30) }

      it 'assigns the canonical armor' do
        expect { validate }
          .to change(armor, :canonical_armor)
                .from(nil)
                .to(matching_canonical)
      end

      it 'sets the attributes', :aggregate_failures do
        validate
        expect(armor.name).to eq 'Steel Plate Armor'
        expect(armor.magical_effects).to eq 'Something'
        expect(armor.unit_weight).to eq 20
        expect(armor.weight).to eq 'heavy armor'
      end
    end

    context 'when there are multiple matching canonical models' do
      let!(:matching_canonicals) { create_list(:canonical_armor, 2, :with_enchantments, name: 'Steel Plate Armor', weight: 'heavy armor') }

      let(:armor) { build(:armor, name: 'Steel plate armor') }

      it "doesn't set the corresponding canonical armor" do
        validate
        expect(armor.canonical_armor).to be_nil
      end

      it "doesn't set other attributes", :aggregate_failures do
        validate
        expect(armor.name).to eq 'Steel plate armor'
        expect(armor.weight).to be_nil
        expect(armor.unit_weight).to be_nil
      end
    end

    context 'when there are no matching canonical models' do
      let(:armor) { build(:armor) }

      it 'is invalid' do
        validate
        expect(armor.errors[:base]).to include "doesn't match any item that exists in Skyrim"
      end
    end

    context 'when updating in-game item attributes' do
      let(:armor) { create(:armor, :with_enchanted_canonical) }

      before do
        armor.canonical_armor.update!(enchantable: true)

        create(:enchantables_enchantment, enchantable: armor, added_automatically: false)

        armor.enchantables_enchantments.reload
      end

      context 'when the update changes the canonical association' do
        let!(:new_canonical) { create(:canonical_armor, name: 'Imperial Boots of Resist Frost', weight: 'light armor', magical_effects: 'This Will Be Case Insensitive', unit_weight: 2) }

        before do
          create(:enchantables_enchantment, enchantable: new_canonical, enchantment: armor.enchantables_enchantments.added_manually.first.enchantment)

          new_canonical.enchantables_enchantments.reload
        end

        it 'changes the canonical association' do
          armor.name = 'Imperial boots of resist frost'
          armor.magical_effects = 'this will be case insensitive'
          armor.weight = nil
          armor.unit_weight = nil

          expect { validate }
            .to change(armor, :canonical_armor)
                  .to(new_canonical)
        end

        it 'sets attributes on the in-game item', :aggregate_failures do
          armor.name = 'Imperial boots of resist frost'
          armor.magical_effects = 'this will be case insensitive'
          armor.weight = nil
          armor.unit_weight = nil

          validate

          expect(armor.name).to eq 'Imperial Boots of Resist Frost'
          expect(armor.magical_effects).to eq 'This Will Be Case Insensitive'
          expect(armor.weight).to eq 'light armor'
          expect(armor.unit_weight).to eq 2
        end

        it 'removes automatically added enchantments', :aggregate_failures do
          armor.name = 'Imperial boots of resist frost'
          armor.magical_effects = 'this will be case insensitive'
          armor.weight = nil
          armor.unit_weight = nil

          validate
          armor.enchantables_enchantments.reload

          expect(armor.enchantables_enchantments.count).to eq 1
          expect(armor.enchantables_enchantments.pluck(:added_automatically)).to be_all(false)
        end
      end

      context 'when the update results in an ambiguous match' do
        before { create_list(:canonical_armor, 2, name: 'Imperial Boots of Resist Frost', weight: 'light armor', magical_effects: 'This Will Be Case Insensitive', unit_weight: 2, enchantable: true) }

        it 'removes the canonical_armor association' do
          armor.name = 'imperial boots of resist frost'
          armor.magical_effects = 'this will be case insensitive'
          armor.weight = nil
          armor.unit_weight = nil

          expect { validate }
            .to change(armor, :canonical_armor)
                  .to(nil)
        end

        it "doesn't set attributes", :aggregate_failures do
          armor.name = 'imperial boots of resist frost'
          armor.magical_effects = 'this will be case insensitive'
          armor.weight = nil
          armor.unit_weight = nil

          validate

          expect(armor.name).to eq 'imperial boots of resist frost'
          expect(armor.magical_effects).to eq 'this will be case insensitive'
          expect(armor.weight).to be_nil
          expect(armor.unit_weight).to be_nil
        end

        it 'removes automatically added enchantments', :aggregate_failures do
          armor.name = 'imperial boots of resist frost'
          armor.magical_effects = 'this will be case insensitive'
          armor.weight = nil
          armor.unit_weight = nil

          validate
          armor.enchantables_enchantments.reload

          expect(armor.enchantables_enchantments.count).to eq 1
          expect(armor.enchantables_enchantments.pluck(:added_automatically)).to be_all(false)
        end
      end

      context 'when the update results in no match' do
        it 'removes the canonical_armor association' do
          armor.name = 'imperial boots of resist frost'

          expect { validate }
            .to change(armor, :canonical_armor)
                  .to(nil)
        end

        it 'removes automatically-added enchantments', :aggregate_failures do
          armor.name = 'imperial boots of resist frost'

          validate
          armor.enchantables_enchantments.reload

          expect(armor.enchantables_enchantments.count).to eq 1
          expect(armor.enchantables_enchantments.pluck(:added_automatically)).to be_all(false)
        end
      end
    end
  end

  describe '::after_create' do
    context 'when there is a single matching canonical model' do
      let!(:matching_canonical) { create(:canonical_armor, :with_enchantments, name: 'Steel Plate Armor', unit_weight: 20, weight: 'heavy armor', magical_effects: 'Something') }

      context "when the new armor doesn't have its own enchantments" do
        let(:armor) { build(:armor, name: 'Steel plate armor', unit_weight: 20) }

        it 'adds enchantments from the canonical armor' do
          armor.save!
          expect(armor.enchantments.length).to eq 2
        end

        it 'sets "added_automatically" to true on new associations' do
          armor.save!

          expect(armor.enchantables_enchantments.pluck(:added_automatically)).to be_all(true)
        end

        it 'sets the correct strengths', :aggregate_failures do
          armor.save!
          matching_canonical.enchantables_enchantments.each do |join_model|
            has_matching = armor.enchantables_enchantments.any? {|model| model.enchantment == join_model.enchantment && model.strength == join_model.strength }

            expect(has_matching).to be true
          end
        end
      end

      context 'when the new armor has its own enchantments' do
        let(:armor) { create(:armor, :with_enchantments, name: 'Steel plate armor', unit_weight: 20) }

        it "doesn't remove the existing enchantments" do
          expect(armor.enchantments.reload.length).to eq 4
        end

        it 'sets "added_automatically" only on the new associations' do
          expect(armor.enchantables_enchantments.pluck(:added_automatically)).to eq [true, true, false, false]
        end
      end
    end

    context 'when there are multiple matching canonical models' do
      let!(:matching_canonicals) { create_list(:canonical_armor, 2, :with_enchantments, name: 'Steel Plate Armor', unit_weight: 20, weight: 'heavy armor', magical_effects: 'Something') }

      let(:armor) { create(:armor, name: 'Steel Plate Armor') }

      it "doesn't add enchantments" do
        expect(armor.enchantments).to be_blank
      end
    end
  end

  describe '#canonical_model' do
    subject(:canonical_model) { armor.canonical_model }

    context 'when there is a canonical armor associated' do
      let(:armor) { create(:armor, :with_matching_canonical) }

      it 'returns the canonical armor' do
        expect(canonical_model).to eq armor.canonical_armor
      end
    end

    context 'when there is no canonical armor associated' do
      let(:armor) { create(:armor) }

      before { create_list(:canonical_armor, 2) }

      it 'returns nil' do
        expect(canonical_model).to be_nil
      end
    end
  end

  describe '#canonical_models' do
    subject(:canonical_models) { armor.canonical_models }

    context 'when there is no existing canonical match' do
      before { create(:canonical_armor, name: 'Something Else') }

      context 'when only the name has to match' do
        let!(:matching_canonicals) { create_list(:canonical_armor, 3, name: armor.name, unit_weight: 2.5) }

        let(:armor) { build(:armor, unit_weight: nil) }

        it 'returns all matching items' do
          expect(canonical_models).to contain_exactly(*matching_canonicals)
        end
      end

      context 'when multiple attributes have to match' do
        let!(:matching_canonicals) { create_list(:canonical_armor, 3, name: armor.name, unit_weight: 2.5) }

        let(:armor) { build(:armor, unit_weight: 2.5) }

        before { create(:canonical_armor, name: armor.name, unit_weight: 1) }

        it 'returns only the items for which all values match' do
          expect(canonical_models).to contain_exactly(*matching_canonicals)
        end
      end

      context 'when there are enchantments' do
        let(:armor) { create(:armor) }
        let(:shared_enchantment) { create(:enchantment) }

        let!(:matching_canonicals) { create_list(:canonical_armor, 2, enchantable: false) }

        before do
          create(:enchantables_enchantment, enchantable: matching_canonicals.first, enchantment: shared_enchantment)

          create(:enchantables_enchantment, enchantable: matching_canonicals.last, enchantment: shared_enchantment)

          create(:enchantables_enchantment, enchantable: matching_canonicals.first)
          create(:enchantables_enchantment, enchantable: matching_canonicals.last)

          matching_canonicals.each {|canonical| canonical.enchantables_enchantments.reload }

          create(:enchantables_enchantment, enchantable: armor, enchantment: shared_enchantment, added_automatically: false)

          create(:enchantables_enchantment, enchantable: armor, enchantment: matching_canonicals.first.enchantments.last, added_automatically: true)

          armor.enchantables_enchantments.reload
        end

        it 'matches based only on manually added enchantments' do
          expect(canonical_models).to contain_exactly(*matching_canonicals)
        end
      end
    end

    context 'when changed attributes lead to a changed canonical' do
      let(:armor) { create(:armor, :with_matching_canonical) }

      let!(:new_canonical) { create(:canonical_armor, name: "Ahzidal's Boots of Waterwalking", unit_weight: 9, weight: 'heavy armor', magical_effects: 'Waterwalking. If you wear any four Relics of Ahzidal, +10 Enchanting.') }

      it 'returns the new canonical' do
        armor.name = "Ahzidal's Boots of Waterwalking"
        armor.unit_weight = 9
        armor.weight = nil
        armor.magical_effects = nil

        expect(canonical_models).to contain_exactly(new_canonical)
      end
    end
  end

  describe 'adding enchantments' do
    let(:armor) { create(:armor, name: 'foobar') }

    before { create_list(:canonical_armor, 2, :with_enchantments, name: 'Foobar', enchantable:) }

    context 'when the added enchantment eliminates all canonical matches' do
      subject(:add_enchantment) { create(:enchantables_enchantment, enchantable: armor) }

      let(:enchantable) { false }

      it "doesn't allow the enchantment to be added", :aggregate_failures do
        expect { add_enchantment }
          .to raise_error(ActiveRecord::RecordInvalid)

        expect(armor.enchantments.reload.length).to eq 0
      end
    end

    context 'when the added enchantment narrows it down to one canonical match' do
      subject(:add_enchantment) { create(:enchantables_enchantment, enchantable: armor, enchantment: Canonical::Armor.last.enchantments.first, strength: Canonical::Armor.last.enchantments.first.strength) }

      let(:enchantable) { false }

      it 'sets the canonical armor' do
        expect { add_enchantment }
          .to change(armor.reload, :canonical_armor)
                .from(nil)
                .to(Canonical::Armor.last)
      end

      it 'adds missing enchantments' do
        add_enchantment
        expect(armor.enchantments.reload.length).to eq 2
      end
    end

    context 'when there are still multiple canonicals after adding the enchantment' do
      subject(:add_enchantment) { create(:enchantables_enchantment, enchantable: armor) }

      let(:enchantable) { true }

      it "doesn't assign a canonical armor" do
        expect { add_enchantment }
          .not_to change(armor.reload, :canonical_armor)
      end

      it "doesn't add additional enchantments" do
        add_enchantment
        expect(armor.enchantments.reload.length).to eq 1
      end
    end
  end
end

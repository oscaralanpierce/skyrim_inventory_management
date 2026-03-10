# frozen_string_literal: true

require 'rails_helper'

RSpec.describe JewelryItem, type: :model do
  describe 'validations' do
    subject(:validate) { item.validate }

    let(:item) { build(:jewelry_item) }

    describe '#name' do
      it 'is invalid without a name' do
        item.name = nil
        validate
        expect(item.errors[:name]).to include("can't be blank")
      end
    end

    describe '#unit_weight' do
      it 'is invalid if less than 0' do
        item.unit_weight = -5
        validate
        expect(item.errors[:unit_weight]).to include('must be greater than or equal to 0')
      end

      it 'can be blank' do
        item.unit_weight = nil
        validate
        expect(item.errors[:unit_weight]).to be_empty
      end
    end

    describe '#canonical_jewelry_item' do
      let(:item) { build(:jewelry_item, canonical_jewelry_item:, game:) }
      let(:game) { create(:game) }

      context 'when the canonical jewelry item is not unique' do
        let(:canonical_jewelry_item) { create(:canonical_jewelry_item) }

        before do
          create_list(
            :jewelry_item,
            3,
            canonical_jewelry_item:,
            game:,
          )
        end

        it 'is valid' do
          expect(item).to be_valid
        end
      end

      context 'when the canonical jewelry item is unique' do
        let(:canonical_jewelry_item) do
          create(
            :canonical_jewelry_item,
            max_quantity: 1,
            unique_item: true,
            rare_item: true,
          )
        end

        context 'when there are no other matching jewelry items' do
          it 'is valid' do
            expect(item).to be_valid
          end
        end

        context 'when there is another matching jewelry item for another game' do
          before do
            create(:jewelry_item, canonical_jewelry_item:)
          end

          it 'is valid' do
            expect(item).to be_valid
          end
        end

        context 'when there is another matching jewelry item for the same game' do
          before do
            create(:jewelry_item, canonical_jewelry_item:, game:)
          end

          it 'is invalid' do
            validate
            expect(item.errors[:base]).to include('is a duplicate of a unique in-game item')
          end
        end
      end
    end

    describe '#canonical_models' do
      context 'when there is a single matching canonical jewelry item' do
        let(:item) { build(:jewelry_item, :with_matching_canonical) }

        it 'is valid' do
          expect(item).to be_valid
        end
      end

      context 'when there are multiple matching canonical jewelry items' do
        before do
          create_list(
            :canonical_jewelry_item,
            2,
            name: item.name,
          )
        end

        it 'is valid' do
          expect(item).to be_valid
        end
      end

      context 'when there are no matching canonical jewelry items' do
        let(:item) { build(:jewelry_item) }

        it 'adds errors' do
          item.validate
          expect(item.errors[:base]).to include("doesn't match any item that exists in Skyrim")
        end
      end
    end
  end

  describe '#crafting_materials' do
    subject(:crafting_materials) { item.crafting_materials }

    context 'when canonical_jewelry_item is set' do
      let!(:canonical_jewelry_item) { create(:canonical_jewelry_item, :with_crafting_materials, name: 'Gold Diamond Ring') }
      let(:item) { create(:jewelry_item, name: 'Gold Diamond Ring', canonical_jewelry_item:) }

      it 'uses the values from the canonical model' do
        expect(crafting_materials).to eq(canonical_jewelry_item.crafting_materials)
      end
    end

    context 'when canonical_jewelry_item is not set' do
      let!(:canonical_models) do
        create_list(
          :canonical_jewelry_item,
          2,
          :with_crafting_materials,
          name: 'Gold Diamond Ring',
        )
      end

      let(:item) { create(:jewelry_item, name: 'Gold Diamond Ring') }

      it 'returns nil' do
        expect(crafting_materials).to be_nil
      end
    end
  end

  describe '#canonical_models' do
    subject(:canonical_models) { item.canonical_models }

    context 'when there are matching canonical models' do
      let(:item) { create(:jewelry_item, name: 'Gold diamond ring') }

      context 'when only the name has to match' do
        let!(:matching_canonicals) do
          create_list(
            :canonical_jewelry_item,
            3,
            name: 'Gold Diamond Ring',
          )
        end

        it 'matches case-insensitively' do
          expect(canonical_models).to contain_exactly(*matching_canonicals)
        end
      end

      context 'when multiple attributes have to match' do
        let!(:matching_canonicals) do
          create_list(
            :canonical_jewelry_item,
            2,
            name: 'Gold Diamond Ring',
            unit_weight: 0.2,
          )
        end

        let(:item) { create(:jewelry_item, name: 'Gold diamond ring', unit_weight: 0.2) }

        before do
          create(:canonical_jewelry_item, name: 'Gold Diamond Ring', unit_weight: 3)
        end

        it 'returns the matching models' do
          expect(canonical_models).to contain_exactly(*matching_canonicals)
        end
      end

      context 'when there are enchantments' do
        let(:item) { create(:jewelry_item) }
        let(:shared_enchantment) { create(:enchantment) }

        let!(:matching_canonicals) do
          create_list(:canonical_jewelry_item, 2, enchantable: false)
        end

        before do
          create(
            :enchantables_enchantment,
            enchantable: matching_canonicals.first,
            enchantment: shared_enchantment,
          )

          create(
            :enchantables_enchantment,
            enchantable: matching_canonicals.last,
            enchantment: shared_enchantment,
          )

          create(:enchantables_enchantment, enchantable: matching_canonicals.first)
          create(:enchantables_enchantment, enchantable: matching_canonicals.last)

          matching_canonicals.each {|canonical| canonical.enchantables_enchantments.reload }

          create(
            :enchantables_enchantment,
            enchantable: item,
            enchantment: shared_enchantment,
            added_automatically: false,
          )

          create(
            :enchantables_enchantment,
            enchantable: item,
            enchantment: matching_canonicals.first.enchantments.last,
            added_automatically: true,
          )

          item.enchantables_enchantments.reload
        end

        it 'matches based only on manually added enchantments' do
          expect(canonical_models).to contain_exactly(*matching_canonicals)
        end
      end
    end

    context 'when there are no matching canonical models' do
      let(:item) { build(:jewelry_item) }

      it 'is empty' do
        expect(canonical_models).to be_empty
      end
    end

    context 'when the canonical model changes' do
      let(:item) { create(:jewelry_item, :with_matching_canonical) }

      let!(:new_canonical) do
        create(
          :canonical_jewelry_item,
          name: "Neloth's Ring of Tracking",
          jewelry_type: 'ring',
          unit_weight: 0.3,
          magical_effects: 'When close enough, identifies the source of the ash spawn attacks on Tel Mithryn',
        )
      end

      it 'returns the new canonical' do
        item.name = "Neloth's Ring of Tracking"
        item.unit_weight = nil
        item.magical_effects = nil

        expect(canonical_models).to contain_exactly(new_canonical)
      end
    end
  end

  describe 'adding enchantments' do
    let(:item) { create(:jewelry_item, name: 'foobar') }

    before do
      create_list(
        :canonical_jewelry_item,
        2,
        :with_enchantments,
        name: 'Foobar',
        enchantable:,
      )
    end

    context 'when the added enchantment eliminates all canonical matches' do
      subject(:add_enchantment) { create(:enchantables_enchantment, enchantable: item) }

      let(:enchantable) { false }

      it "doesn't allow the enchantment to be added", :aggregate_failures do
        expect { add_enchantment }
          .to raise_error(ActiveRecord::RecordInvalid)

        expect(item.enchantments.reload.length).to eq(0)
      end
    end

    context 'when the added enchantment narrows it down to one canonical match' do
      subject(:add_enchantment) do
        create(
          :enchantables_enchantment,
          enchantable: item,
          enchantment: Canonical::JewelryItem.last.enchantments.first,
          strength: Canonical::JewelryItem.last.enchantments.first.strength,
        )
      end

      let(:enchantable) { false }

      it 'sets the canonical clothing item' do
        expect { add_enchantment }
          .to change(item.reload, :canonical_jewelry_item)
                .from(nil)
                .to(Canonical::JewelryItem.last)
      end

      it 'adds missing enchantments' do
        add_enchantment
        expect(item.enchantments.reload.length).to eq(2)
      end
    end

    context 'when there are still multiple canonicals after adding the enchantment' do
      subject(:add_enchantment) { create(:enchantables_enchantment, enchantable: item) }

      let(:enchantable) { true }

      it "doesn't assign a canonical clothing item" do
        expect { add_enchantment }
          .not_to change(item.reload, :canonical_jewelry_item)
      end

      it "doesn't add additional enchantments" do
        add_enchantment
        expect(item.enchantments.reload.length).to eq(1)
      end
    end
  end

  describe '#jewelry_type' do
    subject(:jewelry_type) { item.jewelry_type }

    context 'when there is a canonical jewelry item assigned' do
      let(:item) { create(:jewelry_item, canonical_jewelry_item:) }
      let(:canonical_jewelry_item) { create(:canonical_jewelry_item, jewelry_type: 'amulet') }

      it 'returns the jewelry type of the canonical' do
        expect(jewelry_type).to eq('amulet')
      end
    end

    context 'when there is no canonical jewelry item assigned' do
      let(:item) { build(:jewelry_item) }

      it 'returns nil' do
        expect(jewelry_type).to be_nil
      end
    end
  end

  describe '::before_validation' do
    subject(:validate) { item.validate }

    context 'when there is a single matching canonical model' do
      let!(:matching_canonical) do
        create(
          :canonical_jewelry_item,
          :with_enchantments,
          name: 'Gold Diamond Ring',
          unit_weight: 0.2,
          jewelry_type: 'ring',
          magical_effects: 'Some magical effects to differentiate',
        )
      end

      let(:item) do
        build(
          :jewelry_item,
          name: 'Gold diamond ring',
          unit_weight: 0.2,
        )
      end

      before do
        create(:canonical_jewelry_item, name: 'Gold Diamond Ring', unit_weight: 1)
      end

      it 'assigns the canonical jewelry item' do
        validate
        expect(item.canonical_jewelry_item).to eq(matching_canonical)
      end

      it 'sets the attributes', :aggregate_failures do
        validate
        expect(item.name).to eq('Gold Diamond Ring')
        expect(item.unit_weight).to eq(0.2)
        expect(item.magical_effects).to eq('Some magical effects to differentiate')
      end
    end

    context 'when there are multiple matching canonical models' do
      let!(:matching_canonicals) do
        create_list(
          :canonical_jewelry_item,
          2,
          :with_enchantments,
          name: 'Gold Diamond Ring',
          unit_weight: 0.2,
        )
      end

      let(:item) { create(:jewelry_item, name: 'Gold Diamond Ring', unit_weight: 0.2) }

      it "doesn't add enchantments" do
        validate
        expect(item.enchantables_enchantments).to be_blank
      end
    end

    context 'when updating in-game item attributes' do
      let(:item) { create(:jewelry_item, :with_enchanted_canonical) }

      before do
        item.canonical_jewelry_item.update!(enchantable: true)

        create(
          :enchantables_enchantment,
          enchantable: item,
          added_automatically: false,
        )

        item.enchantables_enchantments.reload
      end

      context 'when the update changes the canonical association' do
        let!(:new_canonical) do
          create(
            :canonical_jewelry_item,
            name: 'Silver Jeweled Necklace',
            unit_weight: 3.0,
          )
        end

        before do
          create(
            :enchantables_enchantment,
            enchantable: new_canonical,
            enchantment: item.enchantables_enchantments.added_manually.first.enchantment,
          )

          new_canonical.enchantables_enchantments.reload
        end

        it 'updates the canonical association' do
          item.name = 'silver jeweled necklace'
          item.unit_weight = nil

          expect { validate }
            .to change(item, :canonical_jewelry_item)
                  .to(new_canonical)
        end

        it 'updates attributes', :aggregate_failures do
          item.name = 'silver jeweled necklace'
          item.unit_weight = nil

          validate

          expect(item.name).to eq('Silver Jeweled Necklace')
          expect(item.unit_weight).to eq(3)
        end

        it 'removes automatically added enchantments', :aggregate_failures do
          item.name = 'silver jeweled necklace'
          item.unit_weight = nil

          validate
          item.enchantables_enchantments.reload

          expect(item.enchantables_enchantments.count).to eq(1)
          expect(item.enchantables_enchantments.pluck(:added_automatically)).to be_all(false)
        end
      end

      context 'when the update results in an ambiguous match' do
        before do
          create_list(
            :canonical_jewelry_item,
            2,
            name: 'Silver Jeweled Necklace',
            unit_weight: 3.0,
          )
        end

        it 'removes the associated canonical jewelry item' do
          item.name = 'silver jeweled necklace'
          item.unit_weight = nil

          expect { validate }
            .to change(item, :canonical_jewelry_item)
                  .to(nil)
        end

        it "doesn't update attributes", :aggregate_failures do
          item.name = 'silver jeweled necklace'
          item.unit_weight = nil

          validate

          expect(item.name).to eq('silver jeweled necklace')
          expect(item.unit_weight).to be_nil
        end

        it 'removes automatically-added enchantments', :aggregate_failures do
          item.name = 'silver jeweled necklace'
          item.unit_weight = nil

          validate
          item.enchantables_enchantments.reload

          expect(item.enchantables_enchantments.count).to eq(1)
          expect(item.enchantables_enchantments.pluck(:added_automatically)).to be_all(false)
        end
      end

      context 'when the update results in no canonical matches' do
        it 'removes the associated canonical jewelry item' do
          item.name = 'silver jeweled necklace'

          expect { validate }
            .to change(item, :canonical_jewelry_item)
                  .to(nil)
        end

        it 'removes automatically-added enchantments', :aggregate_failures do
          item.name = 'silver jeweled necklace'
          item.unit_weight = nil

          validate
          item.enchantables_enchantments.reload

          expect(item.enchantables_enchantments.count).to eq(1)
          expect(item.enchantables_enchantments.pluck(:added_automatically)).to be_all(false)
        end
      end
    end
  end

  describe '::after_create' do
    let(:item) { create(:jewelry_item, name: 'Gold Diamond Ring') }

    context 'when there is a single matching canonical model' do
      let!(:matching_canonical) do
        create(
          :canonical_jewelry_item,
          :with_enchantments,
          name: 'Gold Diamond Ring',
        )
      end

      context "when the new item doesn't have its own enchantments" do
        let(:item) do
          build(
            :jewelry_item,
            name: 'Gold diamond ring',
          )
        end

        it 'adds enchantments from the canonical model' do
          item.save!
          expect(item.enchantments.length).to eq(2)
        end

        it 'sets "added_automatically" to true on new associations' do
          item.save!
          expect(item.enchantables_enchantments.pluck(:added_automatically))
            .to be_all(true)
        end

        it 'sets the correct strengths', :aggregate_failures do
          item.save!

          matching_canonical.enchantables_enchantments.each do |join_model|
            has_matching = item.enchantables_enchantments.any? do |model|
              model.enchantment == join_model.enchantment && model.strength == join_model.strength
            end

            expect(has_matching).to be(true)
          end
        end
      end

      context 'when the new item has its own enchantments' do
        let(:item) do
          create(
            :jewelry_item,
            :with_enchantments,
            name: 'Gold diamond ring',
          )
        end

        it "doesn't remove the existing enchantments" do
          item.save!
          expect(item.enchantments.reload.length).to eq(4)
        end

        it 'sets "added_automatically" only on the new associations' do
          item.save!

          expect(item.enchantables_enchantments.pluck(:added_automatically))
            .to eq([true, true, false, false])
        end
      end
    end

    context 'when there are multiple matching canonical models' do
      before do
        create_list(
          :canonical_jewelry_item,
          2,
          :with_enchantments,
          name: 'Gold Diamond Ring',
        )
      end

      it "doesn't set enchantments" do
        expect(item.enchantables_enchantments.length).to eq(0)
      end
    end
  end
end

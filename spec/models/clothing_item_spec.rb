# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ClothingItem, type: :model do
  describe 'validations' do
    let(:item) { build(:clothing_item) }

    it 'is invalid without a name' do
      item.name = nil
      item.validate
      expect(item.errors[:name]).to include("can't be blank")
    end

    it 'is invalid with unit weight less than 0' do
      item.unit_weight = -1
      item.validate
      expect(item.errors[:unit_weight]).to include('must be greater than or equal to 0')
    end

    describe '#canonical_clothing_item' do
      let(:item) { build(:clothing_item, canonical_clothing_item:, game:) }
      let(:game) { create(:game) }

      context 'when the canonical clothing item is not unique' do
        let(:canonical_clothing_item) { create(:canonical_clothing_item) }

        before do
          create_list(
            :clothing_item,
            3,
            canonical_clothing_item:,
            game:,
          )
        end

        it 'is valid' do
          expect(item).to be_valid
        end
      end

      context 'when the canonical clothing item is unique' do
        let(:canonical_clothing_item) do
          create(
            :canonical_clothing_item,
            max_quantity: 1,
            unique_item: true,
            rare_item: true,
          )
        end

        context 'when there are no other matching clothing items' do
          it 'is valid' do
            expect(item).to be_valid
          end
        end

        context 'when there is another matching clothing item for another game' do
          before do
            create(:clothing_item, canonical_clothing_item:)
          end

          it 'is valid' do
            expect(item).to be_valid
          end
        end

        context 'when there is another matching clothing item for the same game' do
          before do
            create(:clothing_item, canonical_clothing_item:, game:)
          end

          it 'is invalid' do
            item.validate
            expect(item.errors[:base]).to include('is a duplicate of a unique in-game item')
          end
        end
      end
    end
  end

  describe '::before_validation' do
    subject(:validate) { item.validate }

    context 'when there is a single matching canonical model' do
      let!(:matching_canonical) do
        create(
          :canonical_clothing_item,
          :with_enchantments,
          name: 'Fine Clothes',
          unit_weight: 1,
          magical_effects: 'Something',
        )
      end

      let(:item) do
        build(
          :clothing_item,
          name: 'Fine clothes',
          unit_weight: 1,
        )
      end

      before do
        create(:canonical_clothing_item, name: 'Fine Clothes', unit_weight: 2)
      end

      it 'assigns the canonical clothing item' do
        validate
        expect(item.canonical_clothing_item).to eq(matching_canonical)
      end

      it 'sets the attributes', :aggregate_failures do
        validate
        expect(item.name).to eq('Fine Clothes')
        expect(item.magical_effects).to eq('Something')
      end
    end

    context 'when there are multiple matching canonical models' do
      let!(:matching_canonicals) do
        create_list(
          :canonical_clothing_item,
          2,
          :with_enchantments,
          name: 'Fine Clothes',
          unit_weight: 1,
        )
      end

      let(:item) { build(:clothing_item, name: 'Fine clothes') }

      it "doesn't set the corresponding canonical clothing item" do
        validate
        expect(item.canonical_clothing_item).to be_nil
      end

      it "doesn't set other attributes", :aggregate_failures do
        validate
        expect(item.name).to eq('Fine clothes')
        expect(item.unit_weight).to be_nil
        expect(item.magical_effects).to be_nil
      end
    end

    context 'when there are no matching canonical models' do
      let(:item) { build(:clothing_item) }

      it 'is invalid' do
        validate
        expect(item.errors[:base]).to include("doesn't match any item that exists in Skyrim")
      end
    end

    context 'when updating in-game item attributes' do
      let(:item) { create(:clothing_item, :with_enchanted_canonical) }

      before do
        item.canonical_clothing_item.update!(enchantable: true)

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
            :canonical_clothing_item,
            name: 'Roughspun Tunic',
            unit_weight: 5,
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
          item.name = 'roughspun tunic'
          item.unit_weight = nil

          expect { validate }
            .to change(item, :canonical_clothing_item)
                  .to(new_canonical)
        end

        it 'updates attributes', :aggregate_failures do
          item.name = 'roughspun tunic'
          item.unit_weight = nil

          validate

          expect(item.name).to eq('Roughspun Tunic')
          expect(item.unit_weight).to eq(5)
        end

        it 'removes automatically added enchantments', :aggregate_failures do
          item.name = 'roughspun tunic'
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
            :canonical_clothing_item,
            2,
            name: 'Roughspun Tunic',
            unit_weight: 5,
          )
        end

        it 'removes the associated canonical clothing item' do
          item.name = 'roughspun tunic'
          item.unit_weight = nil

          expect { validate }
            .to change(item, :canonical_clothing_item)
                  .to(nil)
        end

        it "doesn't update attributes", :aggregate_failures do
          item.name = 'roughspun tunic'
          item.unit_weight = nil

          validate

          expect(item.name).to eq('roughspun tunic')
          expect(item.unit_weight).to be_nil
        end

        it 'removes automatically-added enchantments', :aggregate_failures do
          item.name = 'roughspun tunic'
          item.unit_weight = nil

          validate
          item.enchantables_enchantments.reload

          expect(item.enchantables_enchantments.count).to eq(1)
          expect(item.enchantables_enchantments.pluck(:added_automatically)).to be_all(false)
        end
      end

      context 'when the update results in no canonical matches' do
        it 'removes the associated canonical clothing item' do
          item.name = 'roughspun tunic'
          item.unit_weight = nil

          expect { validate }
            .to change(item, :canonical_clothing_item)
                  .to(nil)
        end

        it 'removes automatically-added enchantments', :aggregate_failures do
          item.name = 'roughspun tunic'
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
    context 'when there is a single matching canonical model' do
      let!(:matching_canonical) do
        create(
          :canonical_clothing_item,
          :with_enchantments,
          name: 'Fine Clothes',
          unit_weight: 1,
          magical_effects: 'Something',
        )
      end

      context "when the new item doesn't have its own enchantments" do
        let(:item) do
          build(
            :clothing_item,
            name: 'Fine clothes',
            unit_weight: 1,
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
            :clothing_item,
            :with_enchantments,
            name: 'Fine clothes',
            unit_weight: 1,
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
      let!(:matching_canonicals) do
        create_list(
          :canonical_clothing_item,
          2,
          :with_enchantments,
          name: 'Fine Clothes',
          unit_weight: 1,
          magical_effects: 'Something',
        )
      end

      let(:item) { build(:clothing_item, name: 'fine clothes') }

      it "doesn't add enchantments" do
        item.save!
        expect(item.enchantments).to be_blank
      end
    end
  end

  describe '#canonical_models' do
    subject(:canonical_models) { item.canonical_models }

    context 'when there are matching canonical models' do
      before do
        create(:canonical_clothing_item, name: 'Something Else')
      end

      context 'when only the name has to match' do
        let!(:matching_canonicals) { create_list(:canonical_clothing_item, 3, name: item.name, unit_weight: 2.5) }

        let(:item) { build(:clothing_item, unit_weight: nil) }

        it 'returns all matching items' do
          expect(canonical_models).to eq(matching_canonicals)
        end
      end

      context 'when multiple attributes have to match' do
        let!(:matching_canonicals) { create_list(:canonical_clothing_item, 3, name: item.name, unit_weight: 2.5) }

        let(:item) { build(:clothing_item, unit_weight: 2.5) }

        before do
          create(:canonical_clothing_item, name: item.name, unit_weight: 1)
        end

        it 'returns only the items for which all values match' do
          expect(canonical_models).to eq(matching_canonicals)
        end
      end

      context 'when there are enchantments' do
        let(:item) { create(:clothing_item) }
        let(:shared_enchantment) { create(:enchantment) }

        let!(:matching_canonicals) do
          create_list(:canonical_clothing_item, 2, enchantable: false)
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

    context "when the matching canonical model isn't the one that's assigned" do
      let(:item) { create(:clothing_item, :with_matching_canonical) }

      let!(:new_canonical) do
        create(
          :canonical_clothing_item,
          name: 'Roughspun Tunic',
          unit_weight: 1,
        )
      end

      it 'returns the matching canonical model' do
        item.name = 'roughspun tunic'
        item.unit_weight = 1

        expect(canonical_models).to contain_exactly(new_canonical)
      end
    end
  end

  describe 'adding enchantments' do
    let(:item) { create(:clothing_item, name: 'foobar') }

    before do
      create_list(
        :canonical_clothing_item,
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
          enchantment: Canonical::ClothingItem.last.enchantments.first,
          strength: Canonical::ClothingItem.last.enchantments.first.strength,
        )
      end

      let(:enchantable) { false }

      it 'sets the canonical clothing item' do
        expect { add_enchantment }
          .to change(item.reload, :canonical_clothing_item)
                .from(nil)
                .to(Canonical::ClothingItem.last)
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
          .not_to change(item.reload, :canonical_clothing_item)
      end

      it "doesn't add additional enchantments" do
        add_enchantment
        expect(item.enchantments.reload.length).to eq(1)
      end
    end
  end
end

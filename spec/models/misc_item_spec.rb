# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MiscItem, type: :model do
  describe 'validations' do
    subject(:validate) { item.validate }

    let(:item) { build(:misc_item) }

    describe '#name' do
      it 'is invalid without a name' do
        item.name = nil
        validate
        expect(item.errors[:name]).to include("can't be blank")
      end
    end

    describe '#unit_weight' do
      it 'can be blank' do
        item.unit_weight = nil
        validate
        expect(item.errors[:unit_weight]).to be_empty
      end

      it 'is invalid if less than 0' do
        item.unit_weight = -1.2
        validate
        expect(item.errors[:unit_weight]).to include('must be greater than or equal to 0')
      end
    end

    describe '#canonical_misc_item' do
      let(:item) { build(:misc_item, canonical_misc_item:, game:) }
      let(:game) { create(:game) }

      context 'when the canonical misc item is not unique' do
        let(:canonical_misc_item) { create(:canonical_misc_item) }

        before do
          create_list(
            :misc_item,
            3,
            canonical_misc_item:,
            game:,
          )
        end

        it 'is valid' do
          expect(item).to be_valid
        end
      end

      context 'when the canonical misc item is unique' do
        let(:canonical_misc_item) do
          create(
            :canonical_misc_item,
            max_quantity: 1,
            unique_item: true,
            rare_item: true,
          )
        end

        context 'when the canonical has no other matches' do
          it 'is valid' do
            expect(item).to be_valid
          end
        end

        context 'when the canonical has another match for a different game' do
          before do
            create(:misc_item, canonical_misc_item:)
          end

          it 'is valid' do
            expect(item).to be_valid
          end
        end

        context 'when the canonical has another match for the same game' do
          before do
            create(:misc_item, canonical_misc_item:, game:)
          end

          it 'is invalid' do
            validate
            expect(item.errors[:base]).to include('is a duplicate of a unique in-game item')
          end
        end
      end
    end

    describe '#canonical_models' do
      context 'when there is a single matching canonical misc item' do
        let(:item) { build(:misc_item, :with_matching_canonical) }

        it 'is valid' do
          expect(item).to be_valid
        end
      end

      context 'when there are multiple matching canonical misc items' do
        let(:item) { build(:misc_item) }

        before do
          create_list(
            :canonical_misc_item,
            2,
            name: item.name,
          )
        end

        it 'is valid' do
          expect(item).to be_valid
        end
      end

      context 'when there are no matching canonical misc items' do
        let(:item) { build(:misc_item) }

        it 'adds errors' do
          validate
          expect(item.errors[:base]).to include("doesn't match any item that exists in Skyrim")
        end
      end
    end
  end

  describe '#canonical_model' do
    subject(:canonical_model) { item.canonical_model }

    context 'when there is a canonical misc item assigned' do
      let(:item) { build(:misc_item, :with_matching_canonical) }

      it 'returns the canonical misc item' do
        expect(canonical_model).to eq(item.canonical_misc_item)
      end
    end

    context 'when there is no canonical misc item assigned' do
      let(:item) { build(:misc_item) }

      it 'returns nil' do
        expect(canonical_model).to be_nil
      end
    end
  end

  describe '#canonical_models' do
    subject(:canonical_models) { item.canonical_models }

    context 'when there are matching canonical models' do
      let(:item) { create(:misc_item, name: 'Wedding Ring') }

      context 'when only the name has to match' do
        let!(:matching_canonicals) do
          create_list(
            :canonical_misc_item,
            3,
            name: 'wedding ring',
          )
        end

        it 'matches case-insensitively' do
          expect(canonical_models).to contain_exactly(*matching_canonicals)
        end
      end

      context 'when both name and unit weight have to match' do
        let!(:matching_canonicals) do
          create_list(
            :canonical_misc_item,
            2,
            name: "Wylandria's Soul Gem",
            unit_weight: 0,
          )
        end

        let(:item) { build(:misc_item, name: "Wylandria's Soul Gem", unit_weight: 0) }

        before do
          create(:canonical_misc_item, name: "Wylandria's Soul Gem", unit_weight: 1.0)
        end

        it 'returns the matching models' do
          expect(canonical_models).to contain_exactly(*matching_canonicals)
        end
      end
    end

    context 'when there are no matching canonical models' do
      let(:item) { build(:misc_item) }

      it 'returns an empty ActiveRecord::Relation', :aggregate_failures do
        expect(canonical_models).to be_an(ActiveRecord::Relation)
        expect(canonical_models).to be_empty
      end
    end

    context 'when the canonical model changes' do
      let(:item) { create(:misc_item, :with_matching_canonical) }

      let!(:new_canonical) do
        create(
          :canonical_misc_item,
          name: 'Jeweled Flagon',
          unit_weight: 0,
        )
      end

      it 'returns the canonical that matches' do
        item.name = 'jeweled flagon'
        item.unit_weight = 0

        expect(canonical_models).to contain_exactly(new_canonical)
      end
    end
  end

  describe '::before_validation' do
    subject(:validate) { item.validate }

    context 'when there is a single matching canonical model' do
      let!(:matching_canonical) do
        create(
          :canonical_misc_item,
          name: "Wylandria's Soul Gem",
          unit_weight: 0,
        )
      end

      let(:item) { build(:misc_item, name: "wylandria's soul gem") }

      it 'assigns the canonical misc item' do
        validate
        expect(item.canonical_misc_item).to eq(matching_canonical)
      end

      it 'sets the attributes', :aggregate_failures do
        validate
        expect(item.name).to eq("Wylandria's Soul Gem")
        expect(item.unit_weight).to eq(0)
      end
    end

    context 'when there are multiple matching canonical models' do
      let!(:matching_canonicals) do
        [
          create(:canonical_misc_item, name: "Wylandria's Soul Gem", unit_weight: 0),
          create(:canonical_misc_item, name: "Wylandria's Soul Gem", unit_weight: 1),
        ]
      end

      let(:item) { create(:misc_item, name: "Wylandria's Soul Gem") }

      it "doesn't set the association" do
        validate
        expect(item.canonical_misc_item).to be_nil
      end
    end

    context 'when updating in-game item attributes' do
      let(:item) { create(:misc_item, :with_matching_canonical) }

      context 'when the update results in a new canonical match' do
        let!(:new_canonical) do
          create(
            :canonical_misc_item,
            name: 'Pill Bottle',
            unit_weight: 0.3,
          )
        end

        it 'associates the new canonical model' do
          item.name = 'pill bottle'
          item.unit_weight = nil

          expect { validate }
            .to change(item, :canonical_misc_item)
                  .to(new_canonical)
        end

        it 'updates attributes', :aggregate_failures do
          item.name = 'pill bottle'
          item.unit_weight = nil

          validate

          expect(item.name).to eq('Pill Bottle')
          expect(item.unit_weight).to eq(0.3)
        end
      end

      context 'when the update results in an ambiguous match' do
        before do
          create_list(
            :canonical_misc_item,
            2,
            name: 'Pill Bottle',
            unit_weight: 0.3,
          )
        end

        it 'sets the canonical misc item to nil' do
          item.name = 'pill bottle'
          item.unit_weight = nil

          expect { validate }
            .to change(item, :canonical_misc_item)
                  .to(nil)
        end

        it "doesn't update attributes", :aggregate_failures do
          item.name = 'pill bottle'
          item.unit_weight = nil

          validate

          expect(item.name).to eq('pill bottle')
          expect(item.unit_weight).to be_nil
        end
      end

      context 'when the update results in no canonical matches' do
        it 'sets the canonical misc item to nil' do
          item.name = 'pill bottle'

          expect { validate }
            .to change(item, :canonical_misc_item)
                  .to(nil)
        end
      end
    end
  end
end

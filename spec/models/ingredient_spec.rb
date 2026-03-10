# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Ingredient, type: :model do
  describe 'validations' do
    subject(:validate) { ingredient.validate }

    let(:ingredient) { build(:ingredient) }

    describe '#name' do
      it "can't be blank" do
        ingredient.name = nil
        validate
        expect(ingredient.errors[:name]).to include("can't be blank")
      end
    end

    describe '#unit_weight' do
      it 'can be blank' do
        ingredient.unit_weight = nil
        validate
        expect(ingredient.errors[:unit_weight]).to be_empty
      end

      it 'must be at least 0' do
        ingredient.unit_weight = -2.7
        validate
        expect(ingredient.errors[:unit_weight]).to include('must be greater than or equal to 0')
      end
    end

    context 'when there are multiple matching canonical ingredients' do
      before do
        create_list(:canonical_ingredient, 3, name: ingredient.name)
      end

      it 'is valid' do
        expect(ingredient).to be_valid
      end
    end

    context 'when there is one matching canonical ingredient' do
      before do
        create(:canonical_ingredient, name: ingredient.name)
      end

      it 'is valid' do
        expect(ingredient).to be_valid
      end
    end

    context 'when there are no matching canonical ingredients' do
      it 'is invalid' do
        validate
        expect(ingredient.errors[:base]).to include("doesn't match any item that exists in Skyrim")
      end
    end

    describe 'canonical ingredient validations' do
      let(:ingredient) { build(:ingredient, canonical_ingredient:, game:) }
      let(:game) { create(:game) }

      context 'when the canonical ingredient is not unique' do
        let(:canonical_ingredient) { create(:canonical_ingredient) }

        before do
          create_list(
            :ingredient,
            3,
            canonical_ingredient:,
            game:,
          )
        end

        it 'is valid' do
          expect(ingredient).to be_valid
        end
      end

      context 'when the canonical ingredient is unique' do
        let(:canonical_ingredient) do
          create(
            :canonical_ingredient,
            max_quantity: 1,
            unique_item: true,
            rare_item: true,
          )
        end

        context 'when the canonical ingredient has no other matches' do
          it 'is valid' do
            expect(ingredient).to be_valid
          end
        end

        context 'when the canonical ingredient has another match for another game' do
          before do
            create(:ingredient, canonical_ingredient:)
          end

          it 'is valid' do
            expect(ingredient).to be_valid
          end
        end

        context 'when the canonical ingredient has another match for the same game' do
          before do
            create(
              :ingredient,
              canonical_ingredient:,
              game:,
            )
          end

          it 'is invalid' do
            validate
            expect(ingredient.errors[:base]).to include('is a duplicate of a unique in-game item')
          end
        end
      end
    end
  end

  describe '#canonical_model' do
    subject(:canonical_model) { ingredient.canonical_model }

    context 'when a canonical ingredient is assigned' do
      let(:ingredient) { create(:ingredient_with_matching_canonical) }

      it 'returns the canonical model' do
        expect(canonical_model).to eq(ingredient.canonical_ingredient)
      end
    end

    context 'when no canonical ingredient is assigned' do
      let(:ingredient) { build(:ingredient) }

      it 'returns nil' do
        expect(canonical_model).to be_nil
      end
    end
  end

  describe '#canonical_models' do
    subject(:canonical_models) { ingredient.canonical_models }

    context 'when there are matching canonical ingredients' do
      context 'when only the names have to match' do
        let!(:matching_canonicals) { create_list(:canonical_ingredient, 3, name: 'Blue Mountain Flower') }
        let(:ingredient) { create(:ingredient, name: 'Blue Mountain Flower') }

        it 'returns all the matching canonical ingredients' do
          expect(ingredient.canonical_models).to eq(matching_canonicals)
        end
      end

      context 'when names and unit weights are defined' do
        let!(:matching_canonicals) { create_list(:canonical_ingredient, 2, name: 'Blue Mountain Flower', unit_weight: 0.1) }
        let(:ingredient) { create(:ingredient, name: 'Blue Mountain Flower', unit_weight: 0.1) }

        before do
          create(:canonical_ingredient, name: 'Blue Mountain Flower', unit_weight: 0.2)
        end

        it 'returns all the matching canonical ingredients' do
          expect(ingredient.canonical_models).to eq(matching_canonicals)
        end
      end

      # NB: No context is required for when no join model fully matches because
      #     join model validations will fail if they don't match.
      context 'when there are also alchemical properties involved' do
        let!(:matching_canonicals) do
          create_list(
            :canonical_ingredient,
            3,
            :with_alchemical_properties,
            name: 'Blue Mountain Flower',
          )
        end

        let(:ingredient) { create(:ingredient, name: 'Blue Mountain Flower') }
        let(:alchemical_property) { matching_canonicals.second.alchemical_properties.reload.second }

        context 'when multiple join models fully match' do
          before do
            matching_canonicals
              .last
              .reload
              .canonical_ingredients_alchemical_properties
              .find_by(priority: alchemical_property.priority)
              .update!(
                alchemical_property:,
              )

            create(
              :ingredients_alchemical_property,
              ingredient:,
              alchemical_property:,
              priority: alchemical_property.priority,
            )

            ingredient.reload
          end

          it 'returns the matching models' do
            expect(canonical_models).to contain_exactly(matching_canonicals.second, matching_canonicals.last)
          end
        end

        context 'when one join model fully matches' do
          before do
            matching_canonicals
              .last
              .reload
              .canonical_ingredients_alchemical_properties
              .find_by(priority: 4)
              .update!(
                alchemical_property:,
              )

            create(
              :ingredients_alchemical_property,
              ingredient:,
              alchemical_property:,
              priority: 4,
            )

            ingredient.reload
          end

          it 'includes only the model that fully matches' do
            expect(canonical_models).to contain_exactly(matching_canonicals.last)
          end
        end
      end
    end

    context 'when there are no matching canonical ingredients' do
      let(:ingredient) { build(:ingredient) }

      it 'is empty' do
        expect(canonical_models).to be_empty
      end
    end

    context 'when the canonical model changes' do
      let(:ingredient) { create(:ingredient_with_matching_canonical) }

      let!(:new_canonical) do
        create(
          :canonical_ingredient,
          name: 'Powdered Mammoth Tusk',
          unit_weight: 0.1,
        )
      end

      it 'returns the canonical that matches' do
        ingredient.name = 'powdered mammoth tusk'
        ingredient.unit_weight = 0.1

        expect(canonical_models).to contain_exactly(new_canonical)
      end
    end
  end

  describe '::before_validation' do
    subject(:validate) { ingredient.validate }

    let(:ingredient) { build(:ingredient) }

    context 'when there is a matching canonical ingredient' do
      let!(:matching_canonical) { create(:canonical_ingredient, name: ingredient.name) }

      it 'sets the canonical_ingredient' do
        validate
        expect(ingredient.canonical_ingredient).to eq(matching_canonical)
      end
    end

    context 'when there are multiple matching canonical ingredients' do
      let!(:matching_canonicals) { create_list(:canonical_ingredient, 2, name: ingredient.name) }

      it "doesn't set the canonical ingredient" do
        validate
        expect(ingredient.canonical_ingredient).to be_nil
      end
    end

    context 'when there is no matching canonical ingredient' do
      it "doesn't set the canonical ingredient" do
        validate
        expect(ingredient.canonical_ingredient).to be_nil
      end
    end

    context 'when updating in-game item attributes' do
      let(:ingredient) { create(:ingredient_with_matching_canonical) }

      context 'when the update changes the canonical match' do
        let!(:new_canonical) do
          create(
            :canonical_ingredient,
            name: 'Horseradish',
            unit_weight: 0.2,
          )
        end

        it 'changes the canonical association' do
          ingredient.name = 'horseradish'
          ingredient.unit_weight = nil

          expect { validate }
            .to change(ingredient, :canonical_ingredient)
                  .to(new_canonical)
        end

        it 'updates attributes', :aggregate_failures do
          ingredient.name = 'horseradish'
          ingredient.unit_weight = nil

          validate

          expect(ingredient.name).to eq('Horseradish')
          expect(ingredient.unit_weight).to eq(0.2)
        end
      end

      context 'when the update results in an ambiguous match' do
        before do
          create_list(
            :canonical_ingredient,
            2,
            name: 'Horseradish',
            unit_weight: 0.2,
          )
        end

        it 'sets the canonical ingredient association to nil' do
          ingredient.name = 'horseradish'
          ingredient.unit_weight = nil

          expect { validate }
            .to change(ingredient, :canonical_ingredient)
                  .to(nil)
        end

        it "doesn't update attributes", :aggregate_failures do
          ingredient.name = 'horseradish'
          ingredient.unit_weight = nil

          validate

          expect(ingredient.name).to eq('horseradish')
          expect(ingredient.unit_weight).to be_nil
        end
      end

      context 'when the update results in no canonical matches' do
        it 'sets the canonical ingredient association to nil' do
          ingredient.name = 'horseradish'

          expect { validate }
            .to change(ingredient, :canonical_ingredient)
                  .to(nil)
        end
      end
    end
  end
end

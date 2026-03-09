# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IngredientsAlchemicalProperty, type: :model do
  describe 'validations' do
    let(:ingredient) { build(:ingredient) }

    describe 'number of records per ingredient' do
      let!(:ingredient) { create(:ingredient_with_matching_canonical, :with_associations_and_properties) }

      before do
        # Since the alchemical properties are added in FactoryBot's after(:create) hook,
        # the ingredient needs to be reloaded before Rails/RSpec will know about them.
        ingredient.reload
      end

      context 'when creating a new record' do
        it 'cannot have more than 4 records corresponding to one ingredient' do
          new_association = build(:ingredients_alchemical_property, ingredient:)

          new_association.validate
          expect(new_association.errors[:ingredient]).to include 'already has 4 alchemical properties'
        end
      end

      context 'when updating a record' do
        context 'when the ingredient_id does not change' do
          it 'is valid' do
            model = ingredient.ingredients_alchemical_properties.first
            model.priority = 4
            model.validate

            expect(model.errors[:ingredient]).to be_empty
          end
        end

        context 'when the ingredient_id changes' do
          context 'when the new ingredient has less than 4 alchemical properties' do
            let!(:new_ingredient) { create(:ingredient_with_matching_canonical, :with_associations_and_properties) }

            before { new_ingredient.reload.ingredients_alchemical_properties.last.destroy! }

            # Validations on this model are strict enough that this is an unlikely
            # scenario. For this reason, it's easiest to test this validator by
            # checking for the specific errors rather than making sure that no
            # validations have failed.
            it 'is valid' do
              model = ingredient.ingredients_alchemical_properties.first
              model.ingredient = new_ingredient
              model.priority = 4
              model.validate

              expect(model.errors[:ingredient]).to be_empty
            end
          end

          context 'when the new ingredient already has exactly 4 alchemical properties' do
            let!(:new_ingredient) { create(:ingredient_with_matching_canonical, :with_associations_and_properties) }

            before { new_ingredient.reload }

            # Validations on this model are strict enough that this is an unlikely
            # scenario. For this reason, it's easiest to test this validator by
            # checking for the specific errors rather than making sure that no
            # validations have failed.
            it 'adds an error' do
              model = ingredient.ingredients_alchemical_properties.first
              model.ingredient = new_ingredient
              model.validate

              expect(model.errors[:ingredient]).to include 'already has 4 alchemical properties'
            end
          end
        end
      end
    end

    describe 'canonical_models' do
      context 'when there is one matching canonical model' do
        let!(:canonical_ingredient) { create(:canonical_ingredient, :with_alchemical_properties) }
        let(:ingredient) { create(:ingredient, canonical_ingredient:) }
        let(:model) { build(:ingredients_alchemical_property, ingredient:) }

        before do
          canonical_ingredient.reload

          model.alchemical_property_id = canonical_ingredient.alchemical_properties.second.id
          model.priority = canonical_ingredient.alchemical_properties.second.priority
          model.save!
        end

        it 'is valid' do
          expect(model).to be_valid
        end
      end

      context 'when are multiple matching canonical models' do
        let!(:canonical_ingredient) { create(:canonical_ingredient, :with_alchemical_properties) }
        let!(:second_canonical) { create(:canonical_ingredient, :with_alchemical_properties) }
        let(:ingredient) { create(:ingredient) }
        let(:join_model) { canonical_ingredient.canonical_ingredients_alchemical_properties.second }
        let(:model) { build(:ingredients_alchemical_property, ingredient:) }

        before do
          canonical_ingredient.reload
          second_canonical.reload

          second_canonical.canonical_ingredients_alchemical_properties.find_by(priority: join_model.priority).update!(alchemical_property_id: join_model.alchemical_property_id)

          model.alchemical_property_id = join_model.alchemical_property_id
          model.priority = join_model.priority
          model.save!
        end

        it 'is valid' do
          expect(model).to be_valid
        end
      end

      context 'when there are no matching canonical models' do
        let!(:canonical_ingredient) { create(:canonical_ingredient) }
        let(:ingredient) { create(:ingredient, canonical_ingredient:) }
        let(:model) { build(:ingredients_alchemical_property, ingredient:) }

        it 'is invalid' do
          model.validate
          expect(model.errors[:base]).to include 'is not consistent with any ingredient that exists in Skyrim'
        end
      end
    end

    describe 'priority' do
      let(:ingredient) { create(:ingredient) }

      before { create(:canonical_ingredient) }

      it "can't be less than 1" do
        model = build(:ingredients_alchemical_property, priority: 0)

        model.validate
        expect(model.errors[:priority]).to include 'must be greater than or equal to 1'
      end

      it "can't be more than 4" do
        model = build(:ingredients_alchemical_property, priority: 5)

        model.validate
        expect(model.errors[:priority]).to include 'must be less than or equal to 4'
      end

      it 'must be an integer' do
        model = build(:ingredients_alchemical_property, priority: 3.2)

        model.validate
        expect(model.errors[:priority]).to include 'must be an integer'
      end

      describe 'uniqueness' do
        before { create(:ingredients_alchemical_property, :valid, priority: 1, ingredient:) }

        it 'must be unique per ingredient' do
          model = build(:ingredients_alchemical_property, priority: 1, ingredient:)

          model.validate
          expect(model.errors[:priority]).to include 'must be unique per ingredient'
        end

        it "doesn't have to be globally unique" do
          model = build(:ingredients_alchemical_property, :valid, priority: 1)

          expect(model).to be_valid
        end
      end
    end

    describe 'alchemical_property_id' do
      it 'must be unique per ingredient' do
        existing_model = create(:ingredients_alchemical_property, :valid)
        model = build(:ingredients_alchemical_property, ingredient: existing_model.ingredient, alchemical_property: existing_model.alchemical_property, priority: 1)

        model.validate
        expect(model.errors[:alchemical_property_id]).to include 'must form a unique combination with ingredient'
      end

      it "doesn't have to be globally unique" do
        existing_model = create(:ingredients_alchemical_property, :valid)
        model = build(:ingredients_alchemical_property, alchemical_property: existing_model.alchemical_property, priority: 1)

        expect(model).to be_valid
      end
    end
  end

  describe '#canonical_models' do
    subject(:canonical_models) { model.canonical_models }

    context 'when there is one matching canonical model' do
      let!(:canonical_ingredient) { create(:canonical_ingredient, :with_alchemical_properties) }
      let(:ingredient) { create(:ingredient, canonical_ingredient:) }
      let(:model) { build(:ingredients_alchemical_property, ingredient:) }

      before do
        canonical_ingredient.reload

        model.alchemical_property_id = canonical_ingredient.alchemical_properties.second.id
        model.priority = canonical_ingredient.alchemical_properties.second.priority
        model.save!
      end

      it 'returns the model' do
        expect(canonical_models).to contain_exactly(canonical_ingredient.canonical_ingredients_alchemical_properties.second)
      end
    end

    context 'when there are multiple matching canonical models' do
      let!(:canonical_ingredient) { create(:canonical_ingredient, :with_alchemical_properties) }
      let!(:second_canonical) { create(:canonical_ingredient, :with_alchemical_properties) }
      let(:ingredient) { create(:ingredient) }
      let(:join_model) { canonical_ingredient.canonical_ingredients_alchemical_properties.second }
      let(:model) { build(:ingredients_alchemical_property, ingredient:) }

      before do
        second_canonical.reload

        second_canonical.canonical_ingredients_alchemical_properties.find_by(priority: join_model.priority).update!(alchemical_property_id: join_model.alchemical_property_id)

        model.alchemical_property_id = join_model.alchemical_property_id
        model.priority = join_model.priority
        model.save!
      end

      it 'returns the matching models' do
        expect(canonical_models).to contain_exactly(*Canonical::IngredientsAlchemicalProperty.where(alchemical_property_id: join_model.alchemical_property_id).to_a)
      end
    end

    context 'when there are no matching canonical models' do
      let!(:canonical_ingredient) { create(:canonical_ingredient) }
      let(:ingredient) { create(:ingredient, canonical_ingredient:) }
      let(:model) { build(:ingredients_alchemical_property, ingredient:) }

      it 'is empty' do
        expect(canonical_models).to be_empty
      end
    end
  end

  describe '#canonical_model' do
    subject(:canonical_model) { model.reload.canonical_model }

    context 'when there is one matching canonical model' do
      let!(:canonical_ingredient) { create(:canonical_ingredient, :with_alchemical_properties) }
      let(:ingredient) { create(:ingredient, canonical_ingredient:) }
      let(:model) { build(:ingredients_alchemical_property, ingredient:) }

      before do
        canonical_ingredient.reload

        model.alchemical_property_id = canonical_ingredient.alchemical_properties.second.id
        model.priority = canonical_ingredient.alchemical_properties.second.priority
        model.save!
      end

      it 'returns the model' do
        expect(canonical_model).to eq canonical_ingredient.canonical_ingredients_alchemical_properties.second
      end
    end

    context 'when are multiple matching canonical models' do
      let!(:canonical_ingredient) { create(:canonical_ingredient, :with_alchemical_properties) }
      let!(:second_canonical) { create(:canonical_ingredient, :with_alchemical_properties) }
      let(:ingredient) { create(:ingredient) }
      let(:join_model) { canonical_ingredient.canonical_ingredients_alchemical_properties.second }
      let(:model) { build(:ingredients_alchemical_property, ingredient:) }

      before do
        second_canonical.reload

        second_canonical.canonical_ingredients_alchemical_properties.find_by(priority: join_model.priority).update!(alchemical_property_id: join_model.alchemical_property_id)

        model.alchemical_property_id = join_model.alchemical_property_id
        model.priority = join_model.priority
        model.save!
      end

      it 'is nil' do
        expect(canonical_model).to be_nil
      end
    end

    context 'when there are no matching canonical models' do
      subject(:canonical_model) { model.canonical_model }

      let!(:canonical_ingredient) { create(:canonical_ingredient) }
      let(:ingredient) { create(:ingredient, canonical_ingredient:) }
      let(:model) { build(:ingredients_alchemical_property, ingredient:) }

      it 'is nil' do
        expect(canonical_model).to be_nil
      end
    end
  end

  describe '#strength_modifier' do
    subject(:strength_modifier) { model.strength_modifier }

    context 'when there is a canonical model' do
      let(:model) { create(:ingredients_alchemical_property, :valid) }

      context 'when the canonical model has a strength_modifier set' do
        before { model.canonical_model.update!(strength_modifier: 1.3) }

        it "returns the canonical model's strength_modifier" do
          expect(strength_modifier).to eq 1.3
        end
      end

      context 'when the canonical model does not have a strength_modifier set' do
        it 'returns 1' do
          expect(strength_modifier).to eq 1
        end
      end
    end

    context 'when there are multiple matching canonicals' do
      let!(:canonical_ingredient) { create(:canonical_ingredient, :with_alchemical_properties) }

      let!(:second_canonical) { create(:canonical_ingredient, :with_alchemical_properties) }

      let(:ingredient) { create(:ingredient) }
      let(:join_model) { canonical_ingredient.canonical_ingredients_alchemical_properties.second }
      let(:model) { build(:ingredients_alchemical_property, ingredient:) }

      before do
        second_canonical.reload

        join_model.update!(strength_modifier: 2)

        second_canonical.canonical_ingredients_alchemical_properties.find_by(priority: join_model.priority).update!(alchemical_property_id: join_model.alchemical_property_id, strength_modifier: 2)

        model.alchemical_property_id = join_model.alchemical_property_id
        model.priority = join_model.priority
        model.save!
      end

      it 'returns nil' do
        expect(strength_modifier).to be_nil
      end
    end
  end

  describe '#duration_modifier' do
    subject(:duration_modifier) { model.duration_modifier }

    context 'when there is a canonical model' do
      let(:model) { create(:ingredients_alchemical_property, :valid) }

      context 'when the canonical model has a duration_modifier set' do
        before { model.canonical_model.update!(duration_modifier: 1.3) }

        it "returns the canonical model's duration_modifier" do
          expect(duration_modifier).to eq 1.3
        end
      end

      context 'when the canonical model does not have a duration_modifier set' do
        it 'returns 1' do
          expect(duration_modifier).to eq 1
        end
      end
    end

    context 'when there are multiple matching canonicals' do
      let!(:canonical_ingredient) { create(:canonical_ingredient, :with_alchemical_properties) }

      let!(:second_canonical) { create(:canonical_ingredient, :with_alchemical_properties) }

      let(:ingredient) { create(:ingredient) }
      let(:join_model) { canonical_ingredient.canonical_ingredients_alchemical_properties.second }
      let(:model) { build(:ingredients_alchemical_property, ingredient:) }

      before do
        second_canonical.reload

        join_model.update!(duration_modifier: 2)

        second_canonical.canonical_ingredients_alchemical_properties.find_by(priority: join_model.priority).update!(alchemical_property_id: join_model.alchemical_property_id, duration_modifier: 2)

        model.alchemical_property_id = join_model.alchemical_property_id
        model.priority = join_model.priority
        model.save!
      end

      it 'returns nil' do
        expect(duration_modifier).to be_nil
      end
    end
  end

  describe '::before_validation' do
    # NB: We don't need a context for when there are no matching canonical
    #     models, because we're testing if values are set from canonical
    #     models, and if there is no canonical model, where would they be
    #     set from?
    context 'when there is a single matching canonical model' do
      let!(:canonical_model) { create(:canonical_ingredients_alchemical_property, priority: 3) }

      let(:canonical_ingredient) { canonical_model.ingredient }
      let(:ingredient) { create(:ingredient, canonical_ingredient:) }

      let(:model) { build(:ingredients_alchemical_property, alchemical_property: canonical_model.alchemical_property, ingredient:, priority: nil) }

      it 'sets values from the canonical model', :aggregate_failures do
        model.validate
        expect(model.priority).to eq 3
      end
    end

    context 'when there are multiple matching canonical models' do
      let!(:canonical_models) { create_list(:canonical_ingredients_alchemical_property, 3, alchemical_property:) }

      let(:alchemical_property) { create(:alchemical_property) }
      let(:ingredient) { create(:ingredient) }

      let(:model) { build(:ingredients_alchemical_property, alchemical_property:, ingredient:, priority: nil) }

      it "doesn't set values", :aggregate_failures do
        model.validate
        expect(model.priority).not_to eq 3
      end
    end
  end
end

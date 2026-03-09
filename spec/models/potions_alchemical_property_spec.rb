# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PotionsAlchemicalProperty, type: :model do
  describe 'validations' do
    let(:model) { build(:potions_alchemical_property) }

    describe 'unique combination of potion and alchemical property' do
      let(:model) { create(:potions_alchemical_property) }
      let(:non_unique_model) { build(:potions_alchemical_property, potion: model.potion, alchemical_property: model.alchemical_property) }

      it 'is invalid with a non-unique combination of potion and alchemical property' do
        non_unique_model.validate
        expect(non_unique_model.errors[:alchemical_property_id]).to include 'must form a unique combination with potion'
      end
    end

    describe '#strength' do
      it 'can be blank' do
        model.strength = nil
        model.validate

        expect(model.errors[:strength]).to be_empty
      end

      it 'is invalid with a non-numeric strength' do
        model.strength = 'foobar'
        model.validate

        expect(model.errors[:strength]).to include 'is not a number'
      end

      it 'is invalid with a non-integer strength' do
        model.strength = 2.3
        model.validate

        expect(model.errors[:strength]).to include 'must be an integer'
      end

      it 'is invalid with a strength of 0 or less' do
        model.strength = -1
        model.validate

        expect(model.errors[:strength]).to include 'must be greater than 0'
      end
    end

    describe '#duration' do
      it 'can be blank' do
        model.duration = nil
        model.validate

        expect(model.errors[:duration]).to be_empty
      end

      it 'is invalid with a non-numeric duration' do
        model.duration = 'foobar'
        model.validate

        expect(model.errors[:duration]).to include 'is not a number'
      end

      it 'is invalid with a non-integer duration' do
        model.duration = 2.3
        model.validate

        expect(model.errors[:duration]).to include 'must be an integer'
      end

      it 'is invalid with a duration of 0 or less' do
        model.duration = -1
        model.validate

        expect(model.errors[:duration]).to include 'must be greater than 0'
      end
    end

    describe '#added_automatically' do
      it 'can be true' do
        model.added_automatically = true

        expect(model).to be_valid
      end

      it "doesn't change a true value" do
        model.added_automatically = true

        expect { model.validate }
          .not_to change(model, :added_automatically)
      end

      it 'can be false' do
        model.added_automatically = false

        expect(model).to be_valid
      end

      it "doesn't change a false value" do
        model.added_automatically = false

        expect { model.validate }
          .not_to change(model, :added_automatically)
      end

      it 'changes a nil value to false' do
        model.added_automatically = nil

        expect { model.validate }
          .to change(model, :added_automatically)
                .to(false)
      end
    end

    describe 'alchemical effects' do
      let(:potion) { create(:potion, :with_matching_canonical) }
      let(:model) { build(:potions_alchemical_property, potion:) }

      context 'when the potion has fewer than 4 effects' do
        before do
          create_list(:potions_alchemical_property, 3, potion:)

          potion.reload
        end

        it 'is valid' do
          expect(model).to be_valid
        end
      end

      context 'when the potion already has 4 or more effects' do
        before do
          create_list(:potions_alchemical_property, 4, potion:)

          potion.reload
        end

        it 'is invalid' do
          model.validate

          expect(model.errors[:potion]).to include 'can have a maximum of 4 effects'
        end
      end
    end
  end

  describe '::added_automatically scope' do
    subject(:added_automatically) { described_class.added_automatically }

    let!(:included_models) { create_list(:potions_alchemical_property, 2, added_automatically: true) }

    before { create(:potions_alchemical_property, added_automatically: false) }

    it 'includes automatically created models only' do
      expect(added_automatically).to contain_exactly(*included_models)
    end
  end

  describe '::added_manually scope' do
    subject(:added_manually) { described_class.added_manually }

    let!(:included_models) { create_list(:potions_alchemical_property, 2, added_automatically: false) }

    before { create(:potions_alchemical_property, added_automatically: true) }

    it 'includes manually created models only' do
      expect(added_manually).to contain_exactly(*included_models)
    end
  end
end

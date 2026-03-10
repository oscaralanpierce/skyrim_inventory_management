# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Ingredient, type: :model do
  describe 'validations' do
    subject(:validate) { model.validate }

    let(:model) { build(:canonical_ingredient) }

    it 'is valid with valid attributes' do
      ingredient = described_class.new(
        name: 'Skeever Tail',
        item_code: 'foo',
        ingredient_type: 'common',
        unit_weight: 1,
        add_on: 'base',
        collectible: true,
        purchasable: true,
        purchase_requires_perk: false,
        unique_item: false,
        rare_item: true,
      )

      expect(ingredient).to be_valid
    end

    describe 'name' do
      it 'must be present' do
        model.name = nil
        validate

        expect(model.errors[:name]).to include("can't be blank")
      end
    end

    describe 'item_code' do
      it 'must be present' do
        model.item_code = nil
        validate

        expect(model.errors[:item_code]).to include("can't be blank")
      end

      it 'must be unique' do
        create(:canonical_ingredient, item_code: 'foo')
        model.item_code = 'foo'
        validate

        expect(model.errors[:item_code]).to include('must be unique')
      end
    end

    describe 'ingredient_type' do
      it 'must have one of the valid values' do
        model.ingredient_type = 'unique'
        validate

        expect(model.errors[:ingredient_type]).to include('must be "common", "uncommon", "rare", or "add_on"')
      end

      it 'can be blank if purchasable is false' do
        model.purchasable = false
        model.purchase_requires_perk = nil
        model.ingredient_type = nil

        expect(model).to be_valid
      end

      it 'must be blank if purchasable is false' do
        model.purchasable = false
        model.purchase_requires_perk = nil
        model.ingredient_type = 'uncommon'
        validate

        expect(model.errors[:ingredient_type]).to include('can only be set for purchasable ingredients')
      end

      it "can't be blank if purchasable is true" do
        model.purchasable = true
        model.purchase_requires_perk = false
        model.ingredient_type = nil
        validate

        expect(model.errors[:ingredient_type]).to include("can't be blank for purchasable ingredients")
      end
    end

    describe 'unit_weight' do
      it 'must be present' do
        model.unit_weight = nil
        validate

        expect(model.errors[:unit_weight]).to include("can't be blank")
      end

      it "can't be less than zero" do
        model.unit_weight = -1
        validate

        expect(model.errors[:unit_weight]).to include('must be greater than or equal to 0')
      end
    end

    describe 'add_on' do
      it 'must be present' do
        model.add_on = nil
        validate

        expect(model.errors[:add_on]).to include("can't be blank")
      end

      it 'must be a valid add-on or DLC' do
        model.add_on = 'fishing'
        validate

        expect(model.errors[:add_on]).to include('must be a SIM-supported add-on or DLC')
      end
    end

    describe 'max_quantity' do
      it 'can be nil' do
        model.max_quantity = nil

        expect(model).to be_valid
      end

      it 'must be greater than zero' do
        model.max_quantity = 0
        validate

        expect(model.errors[:max_quantity]).to include('must be an integer of at least 1')
      end

      it 'must be an integer' do
        model.max_quantity = 1.2
        validate

        expect(model.errors[:max_quantity]).to include('must be an integer of at least 1')
      end
    end

    describe 'collectible' do
      it 'must be true or false' do
        model.collectible = nil
        validate

        expect(model.errors[:collectible]).to include('must be true or false')
      end
    end

    describe 'purchasable' do
      it 'must be true or false' do
        model.purchasable = nil
        validate

        expect(model.errors[:purchasable]).to include('must be true or false')
      end
    end

    describe 'purchase_requires_perk' do
      # Because non-nil values other than `true` or `false` will automatically
      # be converted to `true` prior to validation, it is pointless to test
      # that boolean values are validated when NULL is also allowed, since `nil`
      # is the only value that won't be converted.

      # This spec tests whether the model IS valid when purchase_requires_perk is nil and purchasable is false.
      # The next spec tests the validation error/message.
      it 'can be NULL if purchasable is false' do
        model.purchasable = false
        model.purchase_requires_perk = nil
        model.ingredient_type = nil

        expect(model).to be_valid
      end

      # The above spec tests whether the model is valid when the value is nil and purchasable is false. This
      # spec tests the validation error/message.
      it 'must be NULL if purchasable is false' do
        model.purchasable = false
        model.purchase_requires_perk = true
        validate

        expect(model.errors[:purchase_requires_perk]).to include("can't be set if purchasable is false")
      end

      it 'must be set if purchasable is true' do
        model.purchasable = true
        model.purchase_requires_perk = nil
        validate

        expect(model.errors[:purchase_requires_perk]).to include('must be true or false if purchasable is true')
      end
    end

    describe 'unique_item' do
      it 'must be true or false' do
        model.unique_item = nil
        validate

        expect(model.errors[:unique_item]).to include('must be true or false')
      end

      it 'must be true if max quantity is 1' do
        model.max_quantity = 1
        model.unique_item = false

        validate

        expect(model.errors[:unique_item]).to include('must be true if max quantity is 1')
      end

      it 'must be false if max quantity is not 1' do
        model.max_quantity = 3
        model.unique_item = true

        validate

        expect(model.errors[:unique_item]).to include('must correspond to a max quantity of 1')
      end
    end

    describe 'rare_item' do
      it 'must be true or false' do
        model.rare_item = nil
        validate

        expect(model.errors[:rare_item]).to include('must be true or false')
      end

      it 'must be true if the ingredient is unique' do
        model.unique_item = true
        model.rare_item = false
        validate

        expect(model.errors[:rare_item]).to include('must be true if item is unique')
      end
    end

    describe 'quest_item' do
      it 'must be true or false' do
        model.quest_item = nil
        validate

        expect(model.errors[:quest_item]).to include('must be true or false')
      end
    end
  end

  describe 'default behavior' do
    it 'upcases item codes' do
      ingredient = create(:canonical_ingredient, item_code: 'abc123')
      expect(ingredient.reload.item_code).to eq('ABC123')
    end
  end

  describe 'class methods' do
    describe '::unique_identifier' do
      it 'returns :item_code' do
        expect(described_class.unique_identifier).to eq(:item_code)
      end
    end
  end

  describe 'associations' do
    let!(:ingredient) { create(:canonical_ingredient, :with_alchemical_properties) }

    # Ensure that a key attribute from the join model can be retrieved directly from
    # the alchemical property
    it 'can get the priority from its alchemical properties' do
      expect(ingredient.reload.alchemical_properties.first.priority).to eq(1)
    end

    # Ensure that a key attribute from the associated model can also be retrieved
    # directly
    it 'can get the name from its alchemical properties' do
      expect(ingredient.reload.alchemical_properties.last.name).to eq(AlchemicalProperty.last.name)
    end
  end
end

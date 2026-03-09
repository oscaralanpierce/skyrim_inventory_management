# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Potion, type: :model do
  describe 'validations' do
    subject(:validate) { potion.validate }

    let(:potion) { build(:canonical_potion) }

    describe 'name' do
      it "can't be blank" do
        potion.name = nil
        validate
        expect(potion.errors[:name]).to include "can't be blank"
      end
    end

    describe 'item_code' do
      it "can't be blank" do
        potion.item_code = nil
        validate
        expect(potion.errors[:item_code]).to include "can't be blank"
      end

      it 'must be unique' do
        create(:canonical_potion, item_code: potion.item_code)
        validate
        expect(potion.errors[:item_code]).to include 'must be unique'
      end
    end

    describe 'unit_weight' do
      it "can't be blank" do
        potion.unit_weight = nil
        validate
        expect(potion.errors[:unit_weight]).to include "can't be blank"
      end

      it 'must be a number' do
        model = build(:canonical_potion, unit_weight: 'foo')

        model.validate
        expect(model.errors[:unit_weight]).to include 'is not a number'
      end

      it 'must be at least zero' do
        model = build(:canonical_potion, unit_weight: -0.5)

        model.validate
        expect(model.errors[:unit_weight]).to include 'must be greater than or equal to 0'
      end
    end

    describe 'purchasable' do
      it "can't be blank" do
        potion.purchasable = nil
        validate
        expect(potion.errors[:purchasable]).to include 'must be true or false'
      end
    end

    describe 'unique_item' do
      it "can't be blank" do
        potion.unique_item = nil
        validate
        expect(potion.errors[:unique_item]).to include 'must be true or false'
      end

      it 'must be true if max quantity is 1' do
        potion.max_quantity = 1
        potion.unique_item = false

        validate

        expect(potion.errors[:unique_item]).to include 'must be true if max quantity is 1'
      end

      it 'cannot be true if max quantity is not 1' do
        potion.max_quantity = nil
        potion.unique_item = true

        validate

        expect(potion.errors[:unique_item]).to include 'must correspond to max quantity of 1'
      end
    end

    describe 'rare_item' do
      it "can't be blank" do
        potion.rare_item = nil
        validate
        expect(potion.errors[:rare_item]).to include 'must be true or false'
      end

      it 'must be true if item is unique' do
        potion.unique_item = true
        potion.rare_item = false
        validate
        expect(potion.errors[:rare_item]).to include 'must be true if item is unique'
      end
    end

    describe 'quest_item' do
      it "can't be blank" do
        potion.quest_item = nil
        validate
        expect(potion.errors[:quest_item]).to include 'must be true or false'
      end
    end

    describe 'add_on' do
      it 'is invalid with an unsupported addon' do
        potion.add_on = 'fishing'
        validate
        expect(potion.errors[:add_on]).to include 'must be a SIM-supported add-on or DLC'
      end
    end

    describe 'collectible' do
      it 'is invalid with a non-boolean value' do
        potion.collectible = nil
        validate
        expect(potion.errors[:collectible]).to include 'must be true or false'
      end
    end

    describe 'max_quantity' do
      it 'is invalid if not an integer' do
        potion.max_quantity = 4.2
        validate
        expect(potion.errors[:max_quantity]).to include 'must be an integer'
      end

      it 'is invalid if less than 1' do
        potion.max_quantity = 0
        validate
        expect(potion.errors[:max_quantity]).to include 'must be greater than 0'
      end

      it 'can be NULL' do
        potion.max_quantity = nil
        expect(potion).to be_valid
      end
    end
  end

  describe 'default behavior' do
    it 'upcases item codes' do
      potion = create(:canonical_potion, item_code: 'abc123')
      expect(potion.reload.item_code).to eq 'ABC123'
    end
  end

  describe 'associations' do
    describe 'alchemical properties' do
      let(:potion) { create(:canonical_potion) }
      let(:alchemical_property) { create(:alchemical_property) }

      before do
        potion.canonical_potions_alchemical_properties.create!(alchemical_property:, strength: 15, duration: 30)

        potion.reload
      end

      it 'returns the alchemical property' do
        expect(potion.alchemical_properties.first).to eq alchemical_property
      end
    end
  end

  describe '::unique_identifier' do
    it 'returns ":item_code"' do
      expect(described_class.unique_identifier).to eq :item_code
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::ClothingItem, type: :model do
  describe 'validations' do
    subject(:validate) { model.validate }

    let(:model) { build(:canonical_clothing_item) }

    it 'is valid with valid attributes' do
      model = described_class.new(name: 'Clothes', item_code: 'foo', unit_weight: 1, body_slot: 'body', add_on: 'base', collectible: true, purchasable: true, unique_item: false, rare_item: false)

      expect(model).to be_valid
    end

    describe 'name' do
      it "can't be blank" do
        model.name = nil
        validate

        expect(model.errors[:name]).to include "can't be blank"
      end
    end

    describe 'item_code' do
      it "can't be blank" do
        model.item_code = nil
        validate

        expect(model.errors[:item_code]).to include "can't be blank"
      end

      it 'must be unique' do
        create(:canonical_clothing_item, item_code: 'xxx')
        model.item_code = 'xxx'

        validate
        expect(model.errors[:item_code]).to include 'must be unique'
      end
    end

    describe 'unit_weight' do
      it "can't be blank" do
        model.unit_weight = nil
        validate

        expect(model.errors[:unit_weight]).to include "can't be blank"
      end

      it 'must be a number' do
        model.unit_weight = 'bar'
        validate

        expect(model.errors[:unit_weight]).to include 'is not a number'
      end

      it 'must be at least zero' do
        model.unit_weight = -34
        validate

        expect(model.errors[:unit_weight]).to include 'must be greater than or equal to 0'
      end
    end

    describe 'body_slot' do
      it "can't be blank" do
        model.body_slot = nil
        validate

        expect(model.errors[:body_slot]).to include "can't be blank"
      end

      it 'must have one of the valid values' do
        model.body_slot = 'bar'
        validate

        expect(model.errors[:body_slot]).to include 'must be "head", "hands", "body", or "feet"'
      end
    end

    describe 'add_on' do
      it "can't be blank" do
        model.add_on = nil
        validate

        expect(model.errors[:add_on]).to include "can't be blank"
      end

      it 'must be a supported add on' do
        model.add_on = 'fishing'
        validate

        expect(model.errors[:add_on]).to include 'must be a SIM-supported add-on or DLC'
      end
    end

    describe 'max_quantity' do
      it 'may be nil' do
        model.max_quantity = nil
        expect(model).to be_valid
      end

      it 'must be greater than zero' do
        model.max_quantity = 0
        validate

        expect(model.errors[:max_quantity]).to include 'must be an integer of at least 1'
      end

      it 'must be an integer' do
        model.max_quantity = 1.2
        validate

        expect(model.errors[:max_quantity]).to include 'must be an integer of at least 1'
      end
    end

    describe 'collectible' do
      it 'must be true or false' do
        model.collectible = nil
        validate

        expect(model.errors[:collectible]).to include 'must be true or false'
      end
    end

    describe 'purchasable' do
      it 'must be true or false' do
        model.purchasable = nil
        validate

        expect(model.errors[:purchasable]).to include 'must be true or false'
      end
    end

    describe 'unique_item' do
      it 'must be true or false' do
        model.unique_item = nil
        validate

        expect(model.errors[:unique_item]).to include 'must be true or false'
      end

      it 'must be true if max quantity is 1' do
        model.max_quantity = 1
        model.unique_item = false

        validate

        expect(model.errors[:unique_item]).to include 'must be true if max quantity is 1'
      end

      it 'must be false if max quantity is not 1' do
        model.max_quantity = nil
        model.unique_item = true

        validate

        expect(model.errors[:unique_item]).to include 'must correspond to a max quantity of 1'
      end
    end

    describe 'rare_item' do
      it 'must be true or false' do
        model.rare_item = nil
        validate

        expect(model.errors[:rare_item]).to include 'must be true or false'
      end

      it 'must be true if item is unique' do
        model.unique_item = true
        model.rare_item = false
        validate

        expect(model.errors[:rare_item]).to include 'must be true if item is unique'
      end
    end

    describe 'quest_item' do
      it 'must be true or false' do
        model.quest_item = nil
        validate

        expect(model.errors[:quest_item]).to include 'must be true or false'
      end
    end

    describe 'enchantable' do
      it 'must be true or false' do
        model.enchantable = nil
        validate

        expect(model.errors[:enchantable]).to include 'must be true or false'
      end
    end
  end

  describe 'default behavior' do
    it 'upcases item codes' do
      item = create(:canonical_clothing_item, item_code: 'abc123')
      expect(item.reload.item_code).to eq 'ABC123'
    end
  end

  describe 'associations' do
    describe 'enchantments' do
      let(:item) { create(:canonical_clothing_item) }
      let(:enchantment) { create(:enchantment) }

      before { item.enchantables_enchantments.create!(enchantment:, strength: 14) }

      it 'gives the enchantment strength' do
        expect(item.enchantments.first.strength).to eq 14
      end
    end
  end

  describe 'class methods' do
    describe '::unique_identifier' do
      it 'returns :item_code' do
        expect(described_class.unique_identifier).to eq :item_code
      end
    end
  end
end

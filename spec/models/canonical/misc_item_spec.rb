# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::MiscItem, type: :model do
  describe 'validations' do
    subject(:validate) { model.validate }

    let(:model) { build(:canonical_misc_item) }

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
        create(:canonical_misc_item, item_code: 'foo')
        model.item_code = 'foo'
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
        model.unit_weight = 'foo'
        validate

        expect(model.errors[:unit_weight]).to include 'is not a number'
      end

      it 'must be at least zero' do
        model.unit_weight = -2
        validate

        expect(model.errors[:unit_weight]).to include 'must be greater than or equal to 0'
      end
    end

    describe 'item_types' do
      it "can't be blank" do
        model.item_types = nil
        validate

        expect(model.errors[:item_types]).to include "can't be blank"
      end

      it 'must include at least one valid type' do
        model.item_types = []
        validate

        expect(model.errors[:item_types]).to include 'must include at least one item type'
      end

      it 'must include only valid types' do
        model.item_types = ['Dwemer artifact', 'industrial equipment']
        validate

        expect(model.errors[:item_types]).to include 'can only include valid item types'
      end
    end

    describe 'add_on' do
      it "can't be blank" do
        model.add_on = nil
        validate

        expect(model.errors[:add_on]).to include "can't be blank"
      end

      it 'must be a supported add-on' do
        model.add_on = 'fishing'
        validate

        expect(model.errors[:add_on]).to include 'must be a SIM-supported add-on or DLC'
      end
    end

    describe 'max_quantity' do
      it 'can be nil' do
        model.max_quantity = nil

        expect(model).to be_valid
      end

      it 'must be at least 1' do
        model.max_quantity = 0
        validate

        expect(model.errors[:max_quantity]).to include 'must be an integer of at least 1'
      end

      it 'must be an integer' do
        model.max_quantity = 2.7
        validate

        expect(model.errors[:max_quantity]).to include 'must be an integer of at least 1'
      end
    end

    describe 'purchasable' do
      it "can't be blank" do
        model.purchasable = nil
        validate

        expect(model.errors[:purchasable]).to include 'must be true or false'
      end
    end

    describe 'collectible' do
      it "can't be blank" do
        model.collectible = nil
        validate

        expect(model.errors[:collectible]).to include 'must be true or false'
      end
    end

    describe 'unique_item' do
      it "can't be blank" do
        model.unique_item = nil
        validate

        expect(model.errors[:unique_item]).to include 'must be true or false'
      end

      it 'must be true if max_quantity is 1' do
        model.unique_item = false
        model.max_quantity = 1

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
      it "can't be blank" do
        model.rare_item = nil
        validate

        expect(model.errors[:rare_item]).to include 'must be true or false'
      end

      it 'must be true if unique_item is true' do
        model.unique_item = true
        model.rare_item = false
        validate

        expect(model.errors[:rare_item]).to include 'must be true if item is unique'
      end
    end

    describe 'quest_item' do
      it "can't be blank" do
        model.quest_item = nil
        validate

        expect(model.errors[:quest_item]).to include 'must be true or false'
      end
    end

    describe 'quest_reward' do
      it "can't be blank" do
        model.quest_reward = nil
        validate

        expect(model.errors[:quest_reward]).to include 'must be true or false'
      end
    end
  end

  describe 'default behavior' do
    it 'upcases the item code' do
      item = create(:canonical_misc_item, item_code: 'abc123')
      expect(item.reload.item_code).to eq 'ABC123'
    end
  end

  describe 'class methods' do
    describe '::unique_identifier' do
      it 'returns ":item_code"' do
        expect(described_class.unique_identifier).to eq :item_code
      end
    end
  end
end

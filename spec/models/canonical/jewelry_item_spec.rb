# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::JewelryItem, type: :model do
  describe 'validations' do
    subject(:validate) { model.validate }

    let(:model) { build(:canonical_jewelry_item) }

    describe 'name' do
      it "can't be blank" do
        model.name = nil
        validate

        expect(model.errors[:name]).to include("can't be blank")
      end
    end

    describe 'item_code' do
      it "can't be blank" do
        model.item_code = nil
        validate

        expect(model.errors[:item_code]).to include("can't be blank")
      end

      it 'must be unique' do
        create(:canonical_jewelry_item, item_code: 'xxx')
        model.item_code = 'xxx'
        validate

        expect(model.errors[:item_code]).to include('must be unique')
      end

      it 'is valid with a unique item code' do
        model.item_code = 'xxx'

        expect(model).to be_valid
      end
    end

    describe 'jewelry_type' do
      it 'is invalid without a jewelry_type' do
        model.jewelry_type = nil
        validate

        expect(model.errors[:jewelry_type]).to include("can't be blank")
      end

      it 'is invalid with an invalid jewelry_type' do
        model.jewelry_type = 'bar'
        validate

        expect(model.errors[:jewelry_type]).to include('must be "ring", "circlet", or "amulet"')
      end
    end

    describe 'unit_weight' do
      it 'is invalid without a unit weight' do
        model.unit_weight = nil
        validate

        expect(model.errors[:unit_weight]).to include("can't be blank")
      end

      it 'is invalid with a non-numeric unit weight' do
        model.unit_weight = 'bar'
        validate

        expect(model.errors[:unit_weight]).to include('is not a number')
      end

      it 'is invalid with a negative unit weight' do
        model.unit_weight = -4.3
        validate

        expect(model.errors[:unit_weight]).to include('must be greater than or equal to 0')
      end
    end

    describe 'add_on' do
      it "can't be blank" do
        model.add_on = nil
        validate

        expect(model.errors[:add_on]).to include("can't be blank")
      end

      it 'must be a valid add-on' do
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

      it 'must be true if the item is unique' do
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

    describe 'quest_reward' do
      it 'must be true or false' do
        model.quest_reward = nil
        validate

        expect(model.errors[:quest_reward]).to include('must be true or false')
      end
    end

    describe 'enchantable' do
      it 'must be true or false' do
        model.enchantable = nil
        validate

        expect(model.errors[:enchantable]).to include('must be true or false')
      end
    end
  end

  describe 'default behavior' do
    it 'upcases item codes' do
      item = create(:canonical_jewelry_item, item_code: 'abc123')
      expect(item.reload.item_code).to eq('ABC123')
    end
  end

  describe 'associations' do
    describe 'enchantments' do
      let(:item) { create(:canonical_jewelry_item) }
      let(:enchantment) { create(:enchantment) }

      before do
        item.enchantables_enchantments.create!(enchantment:, strength: 17)
      end

      it 'gives the enchantment strength' do
        expect(item.enchantments.first.strength).to eq(17)
      end
    end

    describe 'materials' do
      subject(:crafting_materials) { item.crafting_materials }

      let(:item) { create(:canonical_jewelry_item) }
      let(:canonical_materials) do
        [
          create(
            :canonical_material,
            craftable: item,
            quantity: 2,
          ),
          create(
            :canonical_material,
            craftable: item,
            quantity: 3,
          ),
        ]
      end

      before do
        item.reload
      end

      it 'returns the canonical materials used to craft the item' do
        raw_materials = canonical_materials.map(&:source_material)
        expect(item.crafting_materials).to contain_exactly(*raw_materials)
      end
    end
  end

  describe 'class methods' do
    describe '::unique_identifier' do
      it 'returns :item_code' do
        expect(described_class.unique_identifier).to eq(:item_code)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Armor, type: :model do
  describe 'validations' do
    subject(:validate) { armor.validate }

    let(:armor) { build(:canonical_armor) }

    describe 'name' do
      it "can't be blank" do
        armor.name = nil
        validate
        expect(armor.errors[:name]).to include "can't be blank"
      end
    end

    describe 'item_code' do
      it "can't be blank" do
        armor.item_code = nil
        validate
        expect(armor.errors[:item_code]).to include "can't be blank"
      end

      it 'must be unique' do
        create(:canonical_armor, item_code: armor.item_code)
        validate
        expect(armor.errors[:item_code]).to include 'must be unique'
      end
    end

    describe 'weight' do
      it "can't be blank" do
        armor.weight = nil
        validate
        expect(armor.errors[:weight]).to include "can't be blank"
      end

      it 'is invalid with an invalid weight value' do
        armor.weight = 'medium armor'
        validate
        expect(armor.errors[:weight]).to include 'must be "light armor" or "heavy armor"'
      end
    end

    describe 'body_slot' do
      it 'is invalid without a body slot' do
        armor.body_slot = nil
        validate
        expect(armor.errors[:body_slot]).to include "can't be blank"
      end

      it 'is invalid without a valid body slot value' do
        armor.body_slot = 'foo'
        validate
        expect(armor.errors[:body_slot]).to include 'must be "head", "body", "hands", "feet", "hair", or "shield"'
      end
    end

    describe 'unit_weight' do
      it 'is invalid without a unit weight' do
        armor.unit_weight = nil
        validate
        expect(armor.errors[:unit_weight]).to include "can't be blank"
      end

      it 'is invalid with a non-numeric unit weight' do
        armor.unit_weight = 'foo'
        validate
        expect(armor.errors[:unit_weight]).to include 'is not a number'
      end

      it 'is invalid with a negative unit weight' do
        armor.unit_weight = -2.4
        validate
        expect(armor.errors[:unit_weight]).to include 'must be greater than or equal to 0'
      end
    end

    describe 'smithing_perks' do
      it 'must include only valid smithing perks' do
        armor.smithing_perks = ['Titanium Smithing']
        validate
        expect(armor.errors[:smithing_perks]).to include '"Titanium Smithing" is not a valid smithing perk'
      end
    end

    describe 'add_on' do
      it 'must be a supported add-on' do
        armor.add_on = 'fishing'
        validate
        expect(armor.errors[:add_on]).to include 'must be a SIM-supported add-on or DLC'
      end

      it 'must be present' do
        armor.add_on = nil
        validate
        expect(armor.errors[:add_on]).to include "can't be blank"
      end
    end

    describe 'max_quantity' do
      it 'can be null' do
        armor.max_quantity = nil
        expect(armor).to be_valid
      end

      it 'must be at least 1' do
        armor.max_quantity = 0
        validate
        expect(armor.errors[:max_quantity]).to include 'must be an integer of at least 1'
      end

      it 'must be an integer' do
        armor.max_quantity = 1.27
        validate
        expect(armor.errors[:max_quantity]).to include 'must be an integer of at least 1'
      end
    end

    describe 'collectible' do
      it 'must be true or false' do
        armor.collectible = nil
        validate
        expect(armor.errors[:collectible]).to include 'must be true or false'
      end
    end

    describe 'leveled' do
      it 'must be true or false' do
        armor.leveled = nil
        validate
        expect(armor.errors[:leveled]).to include 'must be true or false'
      end
    end

    describe 'purchasable' do
      it 'must be true or false' do
        armor.purchasable = nil
        validate
        expect(armor.errors[:purchasable]).to include 'must be true or false'
      end
    end

    describe 'unique_item' do
      it 'must be true or false' do
        armor.unique_item = nil
        validate
        expect(armor.errors[:unique_item]).to include 'must be true or false'
      end

      it 'must be true if max quantity is 1' do
        armor.max_quantity = 1
        armor.unique_item = false

        validate

        expect(armor.errors[:unique_item]).to include 'must be true if max quantity is 1'
      end

      it 'must be false if max quantity is not 1' do
        armor.max_quantity = 4
        armor.unique_item = true

        validate

        expect(armor.errors[:unique_item]).to include 'must correspond to a max quantity of 1'
      end
    end

    describe 'rare_item' do
      it 'must be true or false' do
        armor.rare_item = nil
        validate
        expect(armor.errors[:rare_item]).to include 'must be true or false'
      end

      it 'must be true if the item is unique' do
        armor.unique_item = true
        armor.rare_item = false
        validate
        expect(armor.errors[:rare_item]).to include 'must be true if item is unique'
      end
    end

    describe 'quest_item' do
      it 'must be true or false' do
        armor.quest_item = nil
        validate
        expect(armor.errors[:quest_item]).to include 'must be true or false'
      end
    end

    describe 'quest_reward' do
      it 'must be true or false' do
        armor.quest_reward = nil
        validate
        expect(armor.errors[:quest_reward]).to include 'must be true or false'
      end
    end

    describe 'enchantable' do
      it 'must be true or false' do
        armor.enchantable = nil
        validate
        expect(armor.errors[:enchantable]).to include 'must be true or false'
      end
    end
  end

  describe 'default behavior' do
    it 'upcases item codes' do
      armor = create(:canonical_armor, item_code: 'abc123')
      expect(armor.reload.item_code).to eq 'ABC123'
    end
  end

  describe 'associations' do
    describe '#enchantments' do
      let(:armor) { create(:canonical_armor) }
      let(:enchantment) { create(:enchantment) }

      before { armor.enchantables_enchantments.create!(enchantment:, strength: 40) }

      it 'gives the enchantment strength' do
        expect(armor.enchantments.first.strength).to eq 40
      end
    end

    describe '#crafting_materials' do
      subject(:crafting_materials) { armor.crafting_materials }

      let(:armor) { create(:canonical_armor) }

      let!(:material1) { create(:canonical_material, craftable: armor).source_material }

      let!(:material2) { create(:canonical_material, craftable: armor, source_material: create(:canonical_ingredient)).source_material }

      it 'returns all crafting materials regardless of class' do
        expect(crafting_materials).to contain_exactly(material1, material2)
      end
    end

    describe '#tempering_materials' do
      subject(:tempering_materials) { armor.tempering_materials }

      let(:armor) { create(:canonical_armor) }

      let!(:material1) { create(:canonical_material, temperable: armor).source_material }

      let!(:material2) { create(:canonical_material, temperable: armor, source_material: create(:canonical_ingredient)).source_material }

      it 'returns all crafting materials regardless of class' do
        expect(tempering_materials).to contain_exactly(material1, material2)
      end
    end
  end

  describe 'class methods' do
    describe 'unique_identifier' do
      it 'returns :item_code' do
        expect(described_class.unique_identifier).to eq :item_code
      end
    end
  end
end

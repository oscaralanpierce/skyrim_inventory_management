# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Weapon, type: :model do
  describe 'validations' do
    subject(:validate) { weapon.validate }

    let(:weapon) { build(:canonical_weapon) }

    it 'is valid with valid attributes' do
      expect(weapon).to be_valid
    end

    describe 'name' do
      it "can't be blank" do
        weapon.name = nil
        validate
        expect(weapon.errors[:name]).to include("can't be blank")
      end
    end

    describe 'item_code' do
      it "can't be blank" do
        weapon.item_code = nil
        validate
        expect(weapon.errors[:item_code]).to include("can't be blank")
      end

      it 'must be unique' do
        create(:canonical_weapon, item_code: weapon.item_code)
        validate
        expect(weapon.errors[:item_code]).to include('must be unique')
      end
    end

    describe 'category' do
      it "can't be blank" do
        weapon.category = nil
        validate
        expect(weapon.errors[:category]).to include("can't be blank")
      end

      it 'must be an allowed value' do
        weapon.category = 'foo'
        validate
        expect(weapon.errors[:category]).to include('must be "one-handed", "two-handed", or "archery"')
      end
    end

    describe 'weapon_type' do
      it "can't be blank" do
        weapon.weapon_type = nil
        validate
        expect(weapon.errors[:weapon_type]).to include("can't be blank")
      end

      it 'must be an allowed value' do
        weapon.weapon_type = 'foo'
        validate
        expect(weapon.errors[:weapon_type]).to include('must be a valid type of weapon that occurs in Skyrim')
      end

      it 'must be valid for the category' do
        weapon.category = 'one-handed'
        weapon.weapon_type = 'crossbow'
        validate
        expect(weapon.errors[:weapon_type]).to include('is not included in category "one-handed"')
      end
    end

    describe 'smithing_perks' do
      it 'must consist of only valid smithing perks', :aggregate_failures do
        weapon.smithing_perks = ['Arcane Blacksmith', 'Silver Smithing', 'Titanium Smithing']
        validate
        expect(weapon.errors[:smithing_perks]).to include('"Silver Smithing" is not a valid smithing perk')
        expect(weapon.errors[:smithing_perks]).to include('"Titanium Smithing" is not a valid smithing perk')
      end
    end

    describe 'base_damage' do
      it 'must be present' do
        weapon.base_damage = nil
        validate
        expect(weapon.errors[:base_damage]).to include("can't be blank")
      end

      it 'must be a number' do
        weapon.base_damage = 'foobar'
        validate
        expect(weapon.errors[:base_damage]).to include('is not a number')
      end

      it 'must be an integer' do
        weapon.base_damage = 1.2
        validate
        expect(weapon.errors[:base_damage]).to include('must be an integer')
      end

      it 'must be at least zero' do
        weapon.base_damage = -2
        validate
        expect(weapon.errors[:base_damage]).to include('must be greater than or equal to 0')
      end
    end

    describe 'add_on' do
      it "can't be blank" do
        weapon.add_on = nil
        validate
        expect(weapon.errors[:add_on]).to include("can't be blank")
      end

      it 'must be a supported add-on' do
        weapon.add_on = 'fishing'
        validate
        expect(weapon.errors[:add_on]).to include('must be a SIM-supported add-on or DLC')
      end
    end

    describe 'max_quantity' do
      it 'can be blank' do
        weapon.max_quantity = nil
        expect(weapon).to be_valid
      end

      it 'must be an integer' do
        weapon.max_quantity = 1.733
        validate
        expect(weapon.errors[:max_quantity]).to include('must be an integer')
      end

      it 'must be greater than 0' do
        weapon.max_quantity = 0
        validate
        expect(weapon.errors[:max_quantity]).to include('must be greater than 0')
      end
    end

    describe 'unit_weight' do
      it 'must be present' do
        weapon.unit_weight = nil
        validate
        expect(weapon.errors[:unit_weight]).to include("can't be blank")
      end

      it 'must be a number' do
        weapon.unit_weight = 'foobar'
        validate
        expect(weapon.errors[:unit_weight]).to include('is not a number')
      end

      it 'must be at least zero' do
        weapon.unit_weight = -2
        validate
        expect(weapon.errors[:unit_weight]).to include('must be greater than or equal to 0')
      end
    end

    describe 'collectible' do
      it 'must be true or false' do
        weapon.collectible = nil
        validate
        expect(weapon.errors[:collectible]).to include('must be true or false')
      end
    end

    describe 'purchasable' do
      it 'must be true or false' do
        weapon.purchasable = nil
        validate
        expect(weapon.errors[:purchasable]).to include('must be true or false')
      end
    end

    describe 'unique_item' do
      it 'must be true or false' do
        weapon.unique_item = nil
        validate
        expect(weapon.errors[:unique_item]).to include('must be true or false')
      end

      it 'must be true if max_quantity is 1' do
        weapon.max_quantity = 1
        weapon.unique_item = false

        validate

        expect(weapon.errors[:unique_item]).to include('must be true if max quantity is 1')
      end

      it 'must be false if max_quantity is not 1' do
        weapon.max_quantity = nil
        weapon.unique_item = true

        validate

        expect(weapon.errors[:unique_item]).to include('must correspond to a max quantity of 1')
      end
    end

    describe 'rare_item' do
      it 'must be true or false' do
        weapon.rare_item = nil
        validate
        expect(weapon.errors[:rare_item]).to include('must be true or false')
      end

      it 'must be true if the item is unique' do
        weapon.unique_item = true
        weapon.rare_item = false
        validate
        expect(weapon.errors[:rare_item]).to include('must be true if item is unique')
      end
    end

    describe 'quest_item' do
      it 'must be true or false' do
        weapon.quest_item = nil
        validate
        expect(weapon.errors[:quest_item]).to include('must be true or false')
      end
    end

    describe 'leveled' do
      it 'must be true or false' do
        weapon.leveled = nil
        validate
        expect(weapon.errors[:leveled]).to include('must be true or false')
      end
    end

    describe 'enchantable' do
      it 'must be true or false' do
        weapon.enchantable = nil
        validate
        expect(weapon.errors[:enchantable]).to include('must be true or false')
      end
    end
  end

  describe 'default behavior' do
    it 'upcases item codes' do
      weapon = create(:canonical_weapon, item_code: 'abc123')
      expect(weapon.reload.item_code).to eq('ABC123')
    end
  end

  describe 'associations' do
    describe 'enchantments' do
      let(:weapon) { create(:canonical_weapon) }
      let(:enchantment) { create(:enchantment) }

      before do
        weapon.enchantables_enchantments.create!(enchantment:, strength: 40)
      end

      it 'gives the enchantment strength' do
        expect(weapon.enchantments.first.strength).to eq(40)
      end
    end

    describe 'powers' do
      let(:weapon) { create(:canonical_weapon) }
      let(:power) { create(:power) }

      before do
        weapon.canonical_powerables_powers.create!(power:)
      end

      it 'retrieves the power' do
        expect(weapon.powers.first).to eq(power)
      end
    end

    describe '#crafting_materials' do
      subject(:crafting_materials) { weapon.crafting_materials }

      let(:weapon) { create(:canonical_weapon) }

      let!(:canonical_materials) do
        [
          create(
            :canonical_material,
            craftable: weapon,
            source_material: create(:canonical_weapon, name: 'Dwarven Crossbow'),
            quantity: 2,
          ).source_material,
          create(
            :canonical_material,
            craftable: weapon,
            source_material: create(:canonical_raw_material, name: 'Dwarven Metal Ingot'),
            quantity: 3,
          ).source_material,
          create(
            :canonical_material,
            craftable: weapon,
            source_material: create(:canonical_ingredient, name: 'Deathbell'),
            quantity: 3,
          ).source_material,
        ]
      end

      before do
        weapon.reload
      end

      it 'returns all crafting materials regardless of class' do
        expect(crafting_materials).to contain_exactly(*canonical_materials)
      end
    end

    describe '#tempering_materials' do
      subject(:tempering_materials) { weapon.tempering_materials }

      let(:weapon) { create(:canonical_weapon) }
      let!(:materials) do
        [
          create(
            :canonical_material,
            temperable: weapon,
            source_material: create(:canonical_raw_material),
          ).source_material,
          create(
            :canonical_material,
            temperable: weapon,
            source_material: create(:canonical_ingredient),
          ).source_material,
        ]
      end

      before do
        weapon.reload
      end

      it 'gives the quantity needed' do
        expect(tempering_materials).to contain_exactly(*materials)
      end
    end
  end

  describe 'class methods' do
    describe '::unique_identifier' do
      subject(:unique_identifier) { described_class.unique_identifier }

      it 'returns :item_code' do
        expect(unique_identifier).to eq(:item_code)
      end
    end
  end
end

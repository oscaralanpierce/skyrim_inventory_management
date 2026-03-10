# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Staff, type: :model do
  describe 'validations' do
    subject(:validate) { staff.validate }

    let(:staff) { build(:canonical_staff) }

    describe 'name' do
      it "can't be blank" do
        staff.name = nil
        validate
        expect(staff.errors[:name]).to include("can't be blank")
      end
    end

    describe 'item_code' do
      it "can't be blank" do
        staff.item_code = nil
        validate
        expect(staff.errors[:item_code]).to include("can't be blank")
      end

      it 'must be unique' do
        create(:canonical_staff, item_code: 'foobar')
        staff.item_code = 'foobar'
        validate
        expect(staff.errors[:item_code]).to include('must be unique')
      end
    end

    describe 'unit_weight' do
      it "can't be blank" do
        staff.unit_weight = nil
        validate
        expect(staff.errors[:unit_weight]).to include("can't be blank")
      end

      it 'must be a number' do
        staff.unit_weight = 'foobar'
        validate
        expect(staff.errors[:unit_weight]).to include('is not a number')
      end

      it 'must be at least zero' do
        staff.unit_weight = -2.2
        validate
        expect(staff.errors[:unit_weight]).to include('must be greater than or equal to 0')
      end
    end

    describe 'base_damage' do
      it "can't be blank" do
        staff.base_damage = nil
        validate
        expect(staff.errors[:base_damage]).to include("can't be blank")
      end

      it 'must be a number' do
        staff.base_damage = 'foobar'
        validate
        expect(staff.errors[:base_damage]).to include('is not a number')
      end

      it 'must be at least zero' do
        staff.base_damage = -1
        validate
        expect(staff.errors[:base_damage]).to include('must be greater than or equal to 0')
      end

      it 'must be an integer' do
        staff.base_damage = 8.2
        validate
        expect(staff.errors[:base_damage]).to include('must be an integer')
      end
    end

    describe 'school' do
      it 'can be blank' do
        staff.school = nil
        expect(staff).to be_valid
      end

      it 'must be an actual school' do
        staff.school = 'Hard Knocks'
        validate
        expect(staff.errors[:school]).to include('must be a valid school of magic')
      end
    end

    describe 'max_quantity' do
      it 'can be blank' do
        staff.max_quantity = nil
        expect(staff).to be_valid
      end

      it 'must be greater than zero' do
        staff.max_quantity = 0
        validate
        expect(staff.errors[:max_quantity]).to include('must be greater than 0')
      end

      it 'must be an integer' do
        staff.max_quantity = 7.45
        validate
        expect(staff.errors[:max_quantity]).to include('must be an integer')
      end
    end

    describe 'add_on' do
      it "can't be blank" do
        staff.add_on = nil
        validate
        expect(staff.errors[:add_on]).to include("can't be blank")
      end

      it 'must be a supported add-on' do
        staff.add_on = 'fishing'
        validate
        expect(staff.errors[:add_on]).to include('must be a SIM-supported add-on or DLC')
      end
    end

    describe 'collectible' do
      it "can't be blank" do
        staff.collectible = nil
        validate
        expect(staff.errors[:collectible]).to include('must be true or false')
      end
    end

    describe 'daedric' do
      it "can't be blank" do
        staff.daedric = nil
        validate
        expect(staff.errors[:daedric]).to include('must be true or false')
      end
    end

    describe 'purchasable' do
      it "can't be blank" do
        staff.purchasable = nil
        validate
        expect(staff.errors[:purchasable]).to include('must be true or false')
      end
    end

    describe 'unique_item' do
      it "can't be blank" do
        staff.unique_item = nil
        validate
        expect(staff.errors[:unique_item]).to include('must be true or false')
      end

      it 'must be true if max quantity is 1' do
        staff.max_quantity = 1
        staff.unique_item = false

        validate

        expect(staff.errors[:unique_item]).to include('must be true if max quantity is 1')
      end

      it 'must be false if max quantity is not 1' do
        staff.max_quantity = 2
        staff.unique_item = true

        validate

        expect(staff.errors[:unique_item]).to include('must correspond to a max quantity of 1')
      end
    end

    describe 'rare_item' do
      it "can't be blank" do
        staff.rare_item = nil
        validate
        expect(staff.errors[:rare_item]).to include('must be true or false')
      end

      it 'must be true if the item is unique' do
        staff.unique_item = true
        staff.rare_item = false

        validate

        expect(staff.errors[:rare_item]).to include('must be true if item is unique')
      end
    end

    describe 'quest_item' do
      it "can't be blank" do
        staff.quest_item = nil
        validate
        expect(staff.errors[:quest_item]).to include('must be true or false')
      end
    end

    describe 'leveled' do
      it "can't be blank" do
        staff.leveled = nil
        validate
        expect(staff.errors[:leveled]).to include('must be true or false')
      end
    end
  end

  describe 'default behavior' do
    it 'upcases item codes' do
      staff = create(:canonical_staff, item_code: 'abc123')
      expect(staff.reload.item_code).to eq('ABC123')
    end
  end

  describe 'associations' do
    describe 'powers' do
      let(:staff) { create(:canonical_staff) }
      let(:power) { create(:power) }

      it 'returns the power' do
        staff.canonical_powerables_powers.create!(power:)
        expect(staff.powers.first).to eq(power)
      end
    end

    describe 'spells' do
      let(:staff) { create(:canonical_staff) }
      let(:spell) { create(:spell) }

      it 'returns the spell' do
        staff.canonical_staves_spells.create!(spell:)
        expect(staff.spells.first).to eq(spell)
      end
    end
  end

  describe 'class methods' do
    describe '::unique_identifier' do
      it 'returns ":item_code"' do
        expect(described_class.unique_identifier).to eq(:item_code)
      end
    end
  end
end

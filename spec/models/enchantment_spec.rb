# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Enchantment, type: :model do
  describe 'validations' do
    subject(:validate) { enchantment.validate }

    let(:enchantment) { build(:enchantment) }

    describe 'name' do
      it "can't be blank" do
        enchantment.name = nil
        validate
        expect(enchantment.errors[:name]).to include("can't be blank")
      end

      it 'must be unique' do
        create(:enchantment, name: 'My Enchantment')
        enchantment.name = 'My Enchantment'

        validate

        expect(enchantment.errors[:name]).to include('must be unique')
      end
    end

    describe 'school' do
      it 'has to be a valid school of magic' do
        enchantment.school = 'Foo'
        validate
        expect(enchantment.errors[:school]).to include('must be a valid school of magic')
      end
    end

    describe 'strength_unit' do
      it 'must be "point", "percentage", "second", or "level"' do
        enchantment.strength_unit = 'foobar'
        validate
        expect(enchantment.errors[:strength_unit]).to include('must be "point", "percentage", "second", or the "level" of affected targets')
      end

      it 'can be blank' do
        enchantment.strength_unit = nil
        expect(enchantment).to be_valid
      end
    end

    describe 'enchantable_items' do
      it 'needs to be one of the valid enchantable items' do
        enchantment.enchantable_items = %w[ring necklace foo]
        validate
        expect(enchantment.errors[:enchantable_items]).to include('must consist of valid enchantable item types')
      end
    end

    describe 'add_on' do
      it "can't be blank" do
        enchantment.add_on = nil
        validate
        expect(enchantment.errors[:add_on]).to include("can't be blank")
      end

      it 'must be a supported add-on' do
        enchantment.add_on = 'fishing'
        validate
        expect(enchantment.errors[:add_on]).to include('must be a SIM-supported add-on or DLC')
      end
    end
  end

  describe 'class methods' do
    describe '::unique_identifier' do
      subject(:unique_identifier) { described_class.unique_identifier }

      it 'returns :name' do
        expect(unique_identifier).to eq(:name)
      end
    end
  end
end

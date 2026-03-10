# frozen_string_literal: true

require 'rails_helper'

RSpec.describe AlchemicalProperty, type: :model do
  describe 'validations' do
    subject(:validate) { model.validate }

    let(:model) { build(:alchemical_property) }

    describe 'name' do
      it "can't be blank" do
        model.name = nil
        validate
        expect(model.errors[:name]).to include("can't be blank")
      end

      it 'must be unique' do
        create(:alchemical_property, name: 'Restore Health', strength_unit: 'point')
        model.name = 'Restore Health'

        validate

        expect(model.errors[:name]).to include('must be unique')
      end
    end

    describe 'description' do
      it "can't be blank" do
        model.description = nil
        validate
        expect(model.errors[:description]).to include("can't be blank")
      end
    end

    describe 'strength_unit' do
      it "isn't required" do
        model.strength_unit = nil
        validate
        expect(model.errors[:strength_unit]).to be_empty
      end

      it 'must be one of "point" or "percentage"' do
        model.strength_unit = 'foobar'
        validate
        expect(model.errors[:strength_unit]).to include('must be "point", "percentage", or the "level" of affected targets')
      end
    end

    describe 'effect_type' do
      it 'is valid if "potion"' do
        model.effect_type = 'potion'
        expect(model).to be_valid
      end

      it 'is valid if "poison"' do
        model.effect_type = 'poison'
        expect(model).to be_valid
      end

      it "can't be blank" do
        model.effect_type = nil
        validate
        expect(model.errors[:effect_type]).to include("can't be blank")
      end

      it "can't be another value" do
        model.effect_type = 'mixed'
        validate
        expect(model.errors[:effect_type]).to include('must be "potion" or "poison"')
      end
    end

    describe 'add_on' do
      it "can't be blank" do
        model.add_on = nil
        validate
        expect(model.errors[:add_on]).to include("can't be blank")
      end

      it 'must be a SIM-supported add-on' do
        model.add_on = 'fishing'
        validate
        expect(model.errors[:add_on]).to include('must be a SIM-supported add-on or DLC')
      end
    end
  end

  describe 'class methods' do
    describe '::unique_identifier' do
      it 'returns :name' do
        expect(described_class.unique_identifier).to eq(:name)
      end
    end
  end
end

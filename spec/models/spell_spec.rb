# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Spell, type: :model do
  describe 'validations' do
    subject(:validate) { spell.validate }

    let(:spell) { build(:spell) }

    describe 'name' do
      it "can't be blank" do
        spell.name = nil
        validate
        expect(spell.errors[:name]).to include("can't be blank")
      end

      it 'must be unique' do
        create(:spell, name: 'Clairvoyance')
        spell.name = 'Clairvoyance'

        validate
        expect(spell.errors[:name]).to include('must be unique')
      end
    end

    describe 'school' do
      it "can't be blank" do
        spell.school = nil
        validate
        expect(spell.errors[:school]).to include("can't be blank")
      end

      it 'must be a valid school of magic' do
        spell.school = 'Alternation'
        validate
        expect(spell.errors[:school]).to include('must be a valid school of magic')
      end
    end

    describe 'level' do
      it "can't be blank" do
        spell.level = nil
        validate
        expect(spell.errors[:level]).to include("can't be blank")
      end

      it 'must be a valid level' do
        spell.level = 'Legendary'
        validate
        expect(spell.errors[:level]).to include('must be "Novice", "Apprentice", "Adept", "Expert", or "Master"')
      end
    end

    describe 'description' do
      it "can't be blank" do
        spell.description = nil
        validate
        expect(spell.errors[:description]).to include("can't be blank")
      end
    end

    describe 'strength and strength_unit' do
      it 'is valid with both a strength and a strength_unit' do
        spell.strength = 50
        spell.strength_unit = 'point'

        expect(spell).to be_valid
      end

      it 'is valid with neither a strength nor a strength_unit' do
        spell.strength = nil
        spell.strength_unit = nil

        expect(spell).to be_valid
      end

      it 'is invalid with a strength but no strength_unit' do
        spell.strength = 50
        validate
        expect(spell.errors[:strength_unit]).to include('must be present if strength is given')
      end

      it 'is invalid with a strength_unit but no strength' do
        spell.strength_unit = 'percentage'
        validate
        expect(spell.errors[:strength]).to include('must be present if strength unit is given')
      end

      it 'requires a valid strength_unit value' do
        spell.strength_unit = 'foo'
        validate
        expect(spell.errors[:strength_unit]).to include('must be "point", "percentage", or the "level" of affected targets')
      end
    end

    describe 'add_on' do
      it "can't be blank" do
        spell.add_on = nil
        validate
        expect(spell.errors[:add_on]).to include("can't be blank")
      end

      it 'must be a supported add-on' do
        spell.add_on = 'fishing'
        validate
        expect(spell.errors[:add_on]).to include('must be a SIM-supported add-on or DLC')
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

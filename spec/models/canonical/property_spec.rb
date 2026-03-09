# frozen_string_literal: true

require 'rails_helper'
require 'skyrim'

RSpec.describe Canonical::Property, type: :model do
  subject(:validate) { property.validate }

  let(:property) { described_class.new }

  describe 'validations' do
    describe 'name' do
      it 'must have a name' do
        validate
        expect(property.errors[:name]).to include "can't be blank"
      end

      it 'must have a valid name' do
        validate
        expect(property.errors[:name]).to include "must be an ownable property in Skyrim, or the Arch-Mage's Quarters"
      end

      it 'must have a unique name' do
        described_class.create!(name: 'Breezehome', hold: 'Whiterun', add_on: 'base')
        property.name = 'Breezehome'
        validate
        expect(property.errors[:name]).to include 'must be unique'
      end
    end

    describe 'hold' do
      it 'must have a valid hold' do
        validate
        expect(property.errors[:hold]).to eq ["can't be blank", 'must be one of the nine Skyrim holds, or Solstheim']
      end

      it 'must have a unique hold' do
        described_class.create!(name: 'Heljarchen Hall', hold: 'The Pale', add_on: 'hearthfire')
        property.hold = 'The Pale'
        validate
        expect(property.errors[:hold]).to eq ['must be unique']
      end
    end

    describe 'city' do
      it 'must have a valid city' do
        property.city = 'Tampa'
        validate
        expect(property.errors[:city]).to eq ['must be a Skyrim city in which an ownable property is located']
      end

      it 'must have a unique city (if not null)' do
        described_class.create!(name: 'Proudspire Manor', hold: 'Haafingar', city: 'Solitude', add_on: 'base')

        property.city = 'Solitude'
        validate
        expect(property.errors[:city]).to eq ['must be unique if present']
      end

      it 'can have a blank city' do
        validate
        expect(property.errors[:city]).to be_blank
      end
    end

    describe 'add_on' do
      it 'must be a valid add-on' do
        property.add_on = 'fishing'
        validate
        expect(property.errors[:add_on]).to include 'must be a SIM-supported add-on or DLC'
      end
    end
  end

  describe 'count limit' do
    before do
      allow(Rails.logger).to receive(:error)

      names_and_holds = described_class::VALID_NAMES.zip(Skyrim::HOLDS)

      names_and_holds.each {|pair| described_class.find_or_create_by!(name: pair[0], hold: pair[1], add_on: 'base') }
    end

    it 'adds a validation error to the base' do
      property.name = 'Breezehome'
      property.hold = 'Whiterun'
      property.validate
      expect(property.errors[:base]).to eq ['cannot create a new canonical property as there are already 10']
    end

    it 'logs an error' do
      property = described_class.new(name: 'Breezehome', hold: 'Whiterun', add_on: 'base')
      property.validate
      expect(Rails.logger).to have_received(:error).with('Cannot create canonical property "Breezehome" in hold "Whiterun": there are already 10 canonical properties')
    end
  end

  describe 'class methods' do
    describe '::unique_identifier' do
      it 'returns :name' do
        expect(described_class.unique_identifier).to eq :name
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Power, type: :model do
  describe 'validations' do
    subject(:validate) { power.validate }

    let(:power) { build(:power) }

    describe 'name' do
      it "can't be blank" do
        power.name = nil
        validate
        expect(power.errors[:name]).to include("can't be blank")
      end

      it 'must be unique' do
        create(:power, name: 'foo')
        power.name = 'foo'

        validate

        expect(power.errors[:name]).to include('must be unique')
      end
    end

    describe 'power_type' do
      it "can't be blank" do
        power.power_type = nil
        validate
        expect(power.errors[:power_type]).to include("can't be blank")
      end

      it 'must be a valid value' do
        power.power_type = 'elemental'
        validate
        expect(power.errors[:power_type]).to include('must be "greater", "lesser", or "ability"')
      end
    end

    describe 'source' do
      it "can't be blank" do
        power.source = nil
        validate
        expect(power.errors[:source]).to include("can't be blank")
      end
    end

    describe 'description' do
      it "can't be blank" do
        power.description = nil
        validate
        expect(power.errors[:description]).to include("can't be blank")
      end
    end

    describe 'add_on' do
      it "can't be blank" do
        power.add_on = nil
        validate
        expect(power.errors[:add_on]).to include("can't be blank")
      end

      it 'must be a supported add-on' do
        power.add_on = 'fishing'
        validate
        expect(power.errors[:add_on]).to include('must be a SIM-supported add-on or DLC')
      end
    end
  end

  describe '::unique_identifier' do
    it 'returns ":name"' do
      expect(described_class.unique_identifier).to eq(:name)
    end
  end
end

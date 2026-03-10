# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::PowerablesPower, type: :model do
  describe 'validations' do
    describe 'powerable item and power' do
      let(:power) { create(:power) }
      let(:staff) { create(:canonical_staff) }

      it 'must form a unique combination' do
        create(:canonical_powerables_power, :for_staff, powerable: staff, power:)
        model = build(:canonical_powerables_power, :for_staff, powerable: staff, power:)

        model.validate
        expect(model.errors[:power_id]).to include('must form a unique combination with powerable item')
      end
    end

    describe 'polymorphic associations' do
      subject(:powerable_type) { described_class.new(powerable: item, power: create(:power)).powerable_type }

      context 'when the association is a staff' do
        let(:item) { create(:canonical_staff) }

        it 'sets the powerable type' do
          expect(powerable_type).to eq('Canonical::Staff')
        end
      end

      context 'when the association is a weapon' do
        let(:item) { create(:canonical_weapon) }

        it 'sets the powerable type' do
          expect(powerable_type).to eq('Canonical::Weapon')
        end
      end
    end
  end
end

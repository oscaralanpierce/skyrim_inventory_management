# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::StavesSpell, type: :model do
  describe 'validations' do
    describe 'strength' do
      it 'can be blank' do
        model = build(:canonical_staves_spell, strength: nil)

        expect(model).to be_valid
      end

      it 'must be a number' do
        model = build(:canonical_staves_spell, strength: 'very strong')

        model.validate
        expect(model.errors[:strength]).to include('is not a number')
      end

      it 'must be greater than zero if present' do
        model = build(:canonical_staves_spell, strength: -2)

        model.validate
        expect(model.errors[:strength]).to include('must be greater than 0')
      end

      it 'must be an integer' do
        model = build(:canonical_staves_spell, strength: 1.7)

        model.validate
        expect(model.errors[:strength]).to include('must be an integer')
      end
    end

    describe 'staff and spell' do
      let(:spell) { create(:spell) }
      let(:staff) { create(:canonical_staff) }

      it 'must form a unique combination' do
        create(:canonical_staves_spell, staff:, spell:)
        model = build(:canonical_staves_spell, staff:, spell:)

        model.validate
        expect(model.errors[:staff_id]).to include('must form a unique combination with spell')
      end
    end
  end
end

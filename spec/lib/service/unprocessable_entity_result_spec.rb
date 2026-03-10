# frozen_string_literal: true

require 'service/unprocessable_entity_result'

RSpec.describe Service::UnprocessableEntityResult do
  subject(:result) { described_class.new(errors: ['Cannot manually update an aggregate list']) }

  describe '#status' do
    it 'is :unprocessable_entity' do
      expect(result.status).to eq(:unprocessable_entity)
    end
  end
end

# frozen_string_literal: true

require 'service/created_result'

RSpec.describe Service::CreatedResult do
  subject(:result) { described_class.new(options) }

  let(:options) { { resource: { foo: 'bar' } } }

  describe '#status' do
    it 'is :created' do
      expect(result.status).to eq :created
    end
  end
end

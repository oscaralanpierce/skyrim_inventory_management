# frozen_string_literal: true

require 'service/not_found_result'

RSpec.describe Service::NotFoundResult do
  subject(:result) { described_class.new({}) }

  describe '#status' do
    it 'is :not_found' do
      expect(result.status).to eq(:not_found)
    end
  end
end

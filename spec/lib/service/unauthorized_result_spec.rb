# frozen_string_literal: true

require 'service/unauthorized_result'

RSpec.describe Service::UnauthorizedResult do
  subject(:result) { described_class.new({}) }

  describe '#status' do
    it 'is :unauthorized' do
      expect(result.status).to eq(:unauthorized)
    end
  end
end

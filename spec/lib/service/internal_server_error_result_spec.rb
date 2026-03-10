# frozen_string_literal: true

require 'service/internal_server_error_result'

RSpec.describe Service::InternalServerErrorResult do
  subject(:result) { described_class.new(errors: ['Something went horribly wrong']) }

  describe '#status' do
    it 'is :internal_server_error' do
      expect(result.status).to eq(:internal_server_error)
    end
  end
end

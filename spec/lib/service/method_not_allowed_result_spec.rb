# frozen_string_literal: true

require 'service/method_not_allowed_result'

RSpec.describe Service::MethodNotAllowedResult do
  subject(:result) { described_class.new(errors: ['Cannot manually update an aggregate list']) }

  describe '#status' do
    it 'is :method_not_allowed' do
      expect(result.status).to eq(:method_not_allowed)
    end
  end
end

# frozen_string_literal: true

require 'service/ok_result'

RSpec.describe Service::OkResult do
  subject(:result) { described_class.new(options) }

  let(:options) do
    {
      resource: { foo: 'bar' },
    }
  end

  describe '#status' do
    it 'is :ok' do
      expect(result.status).to eq :ok
    end
  end
end

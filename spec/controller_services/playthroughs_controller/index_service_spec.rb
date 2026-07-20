# frozen_string_literal: true

require 'rails_helper'
require 'service/internal_server_error_result'
require 'service/ok_result'

RSpec.describe PlaythroughsController::IndexService do
  describe '#perform' do
    subject(:perform) { described_class.new(user).perform }

    context 'when the user has no playthroughs' do
      let(:user) { create(:user) }

      it 'returns a Service::OkResult' do
        expect(perform).to be_a(Service::OkResult)
      end

      it 'sets the resource to an empty array' do
        expect(perform.resource).to eq([])
      end
    end

    context 'when the user has playthroughs' do
      let(:user) { create(:user_with_playthroughs) }

      before do
        create(:playthrough) # another user's playthrough, shouldn't be included
      end

      it 'returns a Service::OkResult' do
        expect(perform).to be_a(Service::OkResult)
      end

      it 'sets the resource to the playthroughs' do
        expect(perform.resource).to eq(user.playthroughs.index_order)
      end
    end

    context 'when something unexpected goes wrong' do
      let(:user) { create(:user_with_playthroughs) }

      before do
        allow_any_instance_of(User).to receive(:playthroughs).and_raise(StandardError, 'Something went horribly wrong')
      end

      it 'returns a Service::InternalServerErrorResult' do
        expect(perform).to be_a(Service::InternalServerErrorResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq(['Something went horribly wrong'])
      end
    end
  end
end

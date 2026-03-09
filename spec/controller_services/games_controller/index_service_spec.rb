# frozen_string_literal: true

require 'rails_helper'
require 'service/ok_result'
require 'service/internal_server_error_result'

RSpec.describe GamesController::IndexService do
  describe '#perform' do
    subject(:perform) { described_class.new(user).perform }

    context 'when the user has no games' do
      let(:user) { create(:user) }

      it 'returns a Service::OkResult' do
        expect(perform).to be_a(Service::OkResult)
      end

      it 'sets the resource to an empty array' do
        expect(perform.resource).to eq([])
      end
    end

    context 'when the user has games' do
      let(:user) { create(:user_with_games) }

      before do
        create(:game) # another user's game, shouldn't be included
      end

      it 'returns a Service::OkResult' do
        expect(perform).to be_a(Service::OkResult)
      end

      it 'sets the resource to the games' do
        expect(perform.resource).to eq(user.games.index_order)
      end
    end

    context 'when something unexpected goes wrong' do
      let(:user) { create(:user_with_games) }

      before { allow_any_instance_of(User).to receive(:games).and_raise(StandardError, 'Something went horribly wrong') }

      it 'returns a Service::InternalServerErrorResult' do
        expect(perform).to be_a(Service::InternalServerErrorResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq(['Something went horribly wrong'])
      end
    end
  end
end

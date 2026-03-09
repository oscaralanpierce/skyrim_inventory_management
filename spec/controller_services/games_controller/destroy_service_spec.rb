# frozen_string_literal: true

require 'rails_helper'
require 'service/no_content_result'
require 'service/not_found_result'
require 'service/internal_server_error_result'

RSpec.describe GamesController::DestroyService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, game.id).perform }

    context 'when all goes well' do
      let!(:user) { create(:user) }
      let!(:game) { create(:game, user:) }

      it 'destroys the game' do
        expect { perform }
          .to change(user.games, :count).from(1).to(0)
      end

      it 'returns a Service::NoContentResult' do
        expect(perform).to be_a(Service::NoContentResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the game does not exist' do
      let!(:user) { create(:user) }
      let(:game) { double(id: 43_598) }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't set data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the game belongs to another user' do
      let!(:user) { create(:user) }
      let!(:game) { create(:game) }

      it "doesn't destroy the game" do
        expect { perform }
          .not_to change(Game, :count)
      end

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end
    end

    context 'when something unexpected goes wrong' do
      let!(:user) { create(:user) }
      let!(:game) { create(:game, user:) }

      before { allow_any_instance_of(Game).to receive(:destroy!).and_raise(StandardError, 'Something went horribly wrong') }

      it 'returns a Service::InternalServerErrorResult' do
        expect(perform).to be_a(Service::InternalServerErrorResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq(['Something went horribly wrong'])
      end
    end
  end
end

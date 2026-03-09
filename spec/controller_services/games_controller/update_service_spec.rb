# frozen_string_literal: true

require 'rails_helper'
require 'service/ok_result'
require 'service/unprocessable_entity_result'
require 'service/not_found_result'
require 'service/internal_server_error_result'

RSpec.describe GamesController::UpdateService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, game.id, params).perform }

    context 'when all goes well' do
      let!(:user) { create(:user) }
      let!(:game) { create(:game, user:) }
      let(:params) { { description: 'New description' } }

      it 'updates the game' do
        perform
        expect(game.reload.description).to eq 'New description'
      end

      it 'returns a Service::OkResult' do
        expect(perform).to be_a(Service::OkResult)
      end

      it 'sets the game as the resource' do
        expect(perform.resource).to eq(game)
      end
    end

    context 'when the params are invalid' do
      let!(:user) { create(:user) }
      let!(:game) { create(:game, user:) }
      let!(:other_game) { create(:game, user:) }
      let(:params) { { name: other_game.name } }

      it "doesn't update the game" do
        perform
        expect(game.reload.name).not_to eq other_game.name
      end

      it 'returns a Service::UnprocessableEntityResult' do
        expect(perform).to be_a(Service::UnprocessableEntityResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq(['Name must be unique'])
      end
    end

    context "when the game doesn't exist" do
      let(:user) { create(:user) }
      let(:game) { double(id: 823_589) }
      let(:params) { { description: 'New description' } }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't set a response body", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the game belongs to another user' do
      let!(:user) { create(:user) }
      let!(:game) { create(:game) }
      let(:params) { { name: 'Valid name' } }

      it "doesn't update the game" do
        perform
        expect(game.reload.name).not_to eq 'Valid name'
      end

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end
    end

    context 'when something unexpected goes wrong' do
      let!(:user) { create(:user) }
      let(:game) { create(:game, user:) }
      let(:params) { { description: 'New description' } }

      before { allow_any_instance_of(Game).to receive(:update).and_raise(StandardError, 'Something went horribly wrong') }

      it 'returns a Service::InternalServerErrorResult' do
        expect(perform).to be_a(Service::InternalServerErrorResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq(['Something went horribly wrong'])
      end
    end
  end
end

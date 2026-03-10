# frozen_string_literal: true

require 'rails_helper'
require 'service/not_found_result'
require 'service/ok_result'

RSpec.describe WishListsController::IndexService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, game_id).perform }

    let(:user) { create(:user) }

    context 'when the game is not found' do
      let(:game_id) { 455_315 }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the game belongs to another user' do
      let(:game_id) { create(:game).id }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when there are no wish lists for that game' do
      let(:game) { create(:game, user:) }
      let(:game_id) { game.id }

      it 'returns a Service::OkResult' do
        expect(perform).to be_a(Service::OkResult)
      end

      it 'sets the resource to be an empty array' do
        expect(perform.resource).to eq([])
      end
    end

    context 'when there are wish lists for that game' do
      let(:game) { create(:game_with_wish_lists, user:) }
      let(:game_id) { game.id }

      it 'returns a Service::OkResult' do
        expect(perform).to be_a(Service::OkResult)
      end

      it "sets the resource to the game's wish lists" do
        expect(perform.resource).to eq(game.wish_lists.index_order)
      end
    end

    context 'when something unexpected goes wrong' do
      let(:game) { create(:game, user:) }
      let(:game_id) { game.id }

      before do
        allow_any_instance_of(Game).to receive(:wish_lists).and_raise(StandardError, 'Something went horribly wrong')
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

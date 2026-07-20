# frozen_string_literal: true

require 'rails_helper'
require 'service/not_found_result'
require 'service/ok_result'

RSpec.describe WishListsController::IndexService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, playthrough_id).perform }

    let(:user) { create(:user) }

    context 'when the playthrough is not found' do
      let(:playthrough_id) { 455_315 }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the playthrough belongs to another user' do
      let(:playthrough_id) { create(:playthrough).id }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when there are no wish lists for that playthrough' do
      let(:playthrough) { create(:playthrough, user:) }
      let(:playthrough_id) { playthrough.id }

      it 'returns a Service::OkResult' do
        expect(perform).to be_a(Service::OkResult)
      end

      it 'sets the resource to be an empty array' do
        expect(perform.resource).to eq([])
      end
    end

    context 'when there are wish lists for that playthrough' do
      let(:playthrough) { create(:playthrough_with_wish_lists, user:) }
      let(:playthrough_id) { playthrough.id }

      it 'returns a Service::OkResult' do
        expect(perform).to be_a(Service::OkResult)
      end

      it "sets the resource to the playthrough's wish lists" do
        expect(perform.resource).to eq(playthrough.wish_lists.index_order)
      end
    end

    context 'when something unexpected goes wrong' do
      let(:playthrough) { create(:playthrough, user:) }
      let(:playthrough_id) { playthrough.id }

      before do
        allow_any_instance_of(Playthrough).to receive(:wish_lists).and_raise(StandardError, 'Something went horribly wrong')
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

# frozen_string_literal: true

require 'rails_helper'
require 'service/internal_server_error_result'
require 'service/method_not_allowed_result'
require 'service/not_found_result'
require 'service/ok_result'
require 'service/unprocessable_entity_result'

RSpec.describe WishListsController::UpdateService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, wish_list.id, params).perform }

    let!(:aggregate_list) { create(:aggregate_wish_list, game:) }
    let(:user) { create(:user) }

    context 'when all goes well' do
      let(:wish_list) { create(:wish_list, game:, aggregate_list:) }
      let(:game) { create(:game, user:) }
      let(:params) { { title: 'My New Title' } }

      it 'updates the wish list' do
        perform
        expect(wish_list.reload.title).to eq('My New Title')
      end

      it 'returns a Service::OkResult' do
        expect(perform).to be_a(Service::OkResult)
      end

      it 'sets the resource to the updated wish list' do
        expect(perform.resource).to eq(wish_list)
      end

      it 'updates the game' do
        t = Time.zone.now + 3.days
        Timecop.freeze(t) do
          perform
          expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
        end
      end
    end

    context 'when the params are invalid' do
      let(:wish_list) { create(:wish_list, game:) }
      let(:game) { create(:game, user:) }
      let(:params) { { title: '|nvalid Tit|e' } }

      it 'returns a Service::UnprocessableEntityResult' do
        expect(perform).to be_a(Service::UnprocessableEntityResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq(["Title can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')"])
      end
    end

    context "when the wish list doesn't exist" do
      let(:wish_list) { double(id: 23_859) }
      let(:game) { create(:game) }
      let(:params) { { title: 'Valid New Title' } }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the wish list belongs to another user' do
      let!(:wish_list) { create(:wish_list) }
      let(:game) { create(:game) }
      let(:params) { { title: 'Valid New Title' } }

      it "doesn't update the wish list" do
        expect { perform }
          .not_to change(wish_list.reload, :title)
      end

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the wish list is an aggregate wish list' do
      let(:wish_list) { aggregate_list }
      let(:game) { create(:game, user:) }
      let(:params) { { title: 'New Title' } }

      it 'returns a Service::MethodNotAllowedResult' do
        expect(perform).to be_a(Service::MethodNotAllowedResult)
      end

      it 'sets the error message' do
        expect(perform.errors).to eq(['Cannot manually update an aggregate wish list'])
      end
    end

    context 'when the request tries to set aggregate to true' do
      let(:wish_list) { create(:wish_list, game:) }
      let(:game) { create(:game, user:) }
      let(:params) { { aggregate: true } }

      it 'returns a Service::UnprocessableEntityResult' do
        expect(perform).to be_a(Service::UnprocessableEntityResult)
      end

      it 'sets the error message' do
        expect(perform.errors).to eq(['Cannot make a regular wish list an aggregate list'])
      end
    end

    context 'when something unexpected goes wrong' do
      let!(:wish_list) { create(:wish_list, game:) }
      let(:game) { create(:game, user:) }
      let(:params) { { title: 'New Title' } }

      before do
        allow_any_instance_of(WishList)
          .to receive(:update)
                .and_raise(StandardError, 'Something went horribly wrong')
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

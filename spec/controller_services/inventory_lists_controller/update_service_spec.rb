# frozen_string_literal: true

require 'rails_helper'
require 'service/ok_result'
require 'service/unprocessable_entity_result'
require 'service/not_found_result'
require 'service/method_not_allowed_result'
require 'service/internal_server_error_result'

RSpec.describe InventoryListsController::UpdateService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, inventory_list.id, params).perform }

    let!(:aggregate_list) { create(:aggregate_inventory_list, game:) }
    let(:user) { create(:user) }
    let(:game) { create(:game, user:) }

    context 'when all goes well' do
      let(:inventory_list) { create(:inventory_list, game:, aggregate_list:) }
      let(:params) { { title: 'My New Title' } }

      it 'updates the inventory list' do
        perform
        expect(inventory_list.reload.title).to eq 'My New Title'
      end

      it 'returns a Service::OkResult' do
        expect(perform).to be_a(Service::OkResult)
      end

      it 'sets the resource to the updated inventory list' do
        expect(perform.resource).to eq inventory_list
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
      let(:inventory_list) { create(:inventory_list, game:) }
      let(:params) { { title: '|nvalid Tit|e' } }

      it 'returns a Service::UnprocessableEntityResult' do
        expect(perform).to be_a(Service::UnprocessableEntityResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq(["Title can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')"])
      end
    end

    context "when the inventory list doesn't exist" do
      let(:inventory_list) { double(id: 23_859) }
      let(:params) { { title: 'Valid New Title' } }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the inventory list belongs to another user' do
      let!(:inventory_list) { create(:inventory_list) }
      let(:params) { { title: 'Valid New Title' } }

      it "doesn't update the inventory list" do
        expect { perform }
          .not_to change(inventory_list.reload, :title)
      end

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the inventory list is an aggregate list' do
      let(:inventory_list) { aggregate_list }
      let(:params) { { title: 'New Title' } }

      it 'returns a Service::MethodNotAllowedResult' do
        expect(perform).to be_a(Service::MethodNotAllowedResult)
      end

      it 'sets the error message' do
        expect(perform.errors).to eq(['Cannot manually update an aggregate inventory list'])
      end
    end

    context 'when the request tries to set aggregate to true' do
      let(:inventory_list) { create(:inventory_list, game:) }
      let(:params) { { aggregate: true } }

      it 'returns a Service::UnprocessableEntityResult' do
        expect(perform).to be_a(Service::UnprocessableEntityResult)
      end

      it 'sets the error message' do
        expect(perform.errors).to eq(['Cannot make a regular inventory list an aggregate list'])
      end
    end

    context 'when something unexpected goes wrong' do
      let(:inventory_list) { create(:inventory_list, game:) }
      let(:params) { { title: 'New Title' } }

      before do
        allow_any_instance_of(InventoryList).to receive(:update).and_raise(StandardError, 'Something went horribly wrong')
      end

      it 'returns a Service::InternalServerErrorResult' do
        expect(perform).to be_a(Service::InternalServerErrorResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq ['Something went horribly wrong']
      end
    end
  end
end

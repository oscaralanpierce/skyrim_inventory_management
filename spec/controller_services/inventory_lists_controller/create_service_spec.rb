# frozen_string_literal: true

require 'rails_helper'
require 'service/created_result'
require 'service/internal_server_error_result'
require 'service/not_found_result'
require 'service/unprocessable_entity_result'

RSpec.describe InventoryListsController::CreateService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, playthrough.id, params).perform }

    let(:user) { create(:user) }

    context 'when the params are valid' do
      let!(:playthrough) { create(:playthrough, user:) }
      let(:params) { { title: 'Hjerim' } }

      context 'when the playthrough has no aggregate inventory list' do
        it 'creates two lists' do
          expect { perform }
            .to change(playthrough.inventory_lists, :count).from(0).to(2)
        end

        it 'creates an aggregate inventory list for the given playthrough' do
          perform
          expect(playthrough.aggregate_inventory_list).to be_present
        end

        it 'creates a regular inventory list for the given playthrough' do
          perform
          expect(playthrough.inventory_lists.last.title).to eq('Hjerim')
        end

        it 'updates the playthrough' do
          t = Time.zone.now + 3.days
          Timecop.freeze(t) do
            perform
            expect(playthrough.reload.updated_at).to be_within(0.005.seconds).of(t)
          end
        end

        it 'returns a Service::CreatedResult' do
          expect(perform).to be_a(Service::CreatedResult)
        end

        it 'sets the resource to include both lists' do
          expect(perform.resource).to eq([playthrough.aggregate_inventory_list, playthrough.inventory_lists.last])
        end
      end

      context 'when the playthrough has an aggregate inventory list' do
        before do
          create(:aggregate_inventory_list, playthrough:)
        end

        it 'creates an inventory list for the given playthrough' do
          expect { perform }
            .to change(playthrough.inventory_lists, :count).from(1).to(2)
        end

        it 'returns a Service::CreatedResult' do
          expect(perform).to be_a(Service::CreatedResult)
        end

        it 'sets the resource to the created list' do
          expect(perform.resource).to eq(playthrough.inventory_lists.last)
        end
      end
    end

    context 'when the params are invalid' do
      let(:playthrough) { create(:playthrough, user:) }
      let(:playthrough_id) { playthrough.id }
      let(:params) { { title: '|nvalid Tit|e' } }

      it "doesn't create an inventory list" do
        expect { perform }
          .not_to change(playthrough.inventory_lists, :count)
      end

      it 'returns a Service::UnprocessableEntityResult' do
        expect(perform).to be_a(Service::UnprocessableEntityResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq(["Title can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')"])
      end
    end

    context 'when the playthrough is not found' do
      let(:playthrough) { double(id: 898_243) }
      let(:params) { { title: 'My Inventory List' } }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data" do
        expect(perform.errors).to be_empty
      end
    end

    context 'when the playthrough belongs to another user' do
      let!(:playthrough) { create(:playthrough) }
      let(:params) { { title: 'My Inventory List' } }

      it "doesn't create an inventory list" do
        expect { perform }
          .not_to change(InventoryList, :count)
      end

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the request tries to create an aggregate list' do
      let(:playthrough) { create(:playthrough, user:) }
      let(:params) do
        {
          title: 'All Items',
          aggregate: true,
        }
      end

      it 'returns a Service::UnprocessableEntityResult' do
        expect(perform).to be_a(Service::UnprocessableEntityResult)
      end

      it 'sets an error' do
        expect(perform.errors).to eq(['Cannot manually create an aggregate inventory list'])
      end
    end

    context 'when something unexpected goes wrong' do
      let(:playthrough) { create(:playthrough, user:) }
      let(:params) { { title: 'Foobar' } }

      before do
        allow_any_instance_of(InventoryList).to receive(:save).and_raise(StandardError, 'Something went horribly wrong')
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

# frozen_string_literal: true

require 'rails_helper'
require 'service/ok_result'
require 'service/no_content_result'
require 'service/method_not_allowed_result'
require 'service/not_found_result'

RSpec.describe InventoryListsController::DestroyService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, inventory_list.id).perform }

    let(:user) { create(:user) }
    let(:game) { create(:game, user:) }

    context 'when all goes well' do
      let!(:aggregate_list) { create(:aggregate_inventory_list, game:) }
      let!(:inventory_list) { create(:inventory_list_with_list_items, game:) }

      before { inventory_list.list_items.each {|list_item| aggregate_list.add_item_from_child_list(list_item) } }

      context 'when the game has additional regular lists' do
        let!(:third_list) { create(:inventory_list_with_list_items, game:, aggregate_list:) }

        before { third_list.list_items.each {|list_item| aggregate_list.add_item_from_child_list(list_item) } }

        it 'destroys the inventory list' do
          expect { perform }
            .to change(game.inventory_lists, :count).from(3).to(2)
        end

        it 'updates the list items on the aggregate list' do
          expect { perform }
            .to change(aggregate_list.list_items, :count).from(4).to(2)
        end

        it 'updates the game' do
          t = Time.zone.now + 3.days
          Timecop.freeze(t) do
            perform
            expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
          end
        end

        it 'returns a Service::OkResult' do
          expect(perform).to be_a Service::OkResult
        end

        it 'sets the resource as the aggregate list' do
          expect(perform.resource).to eq aggregate_list
        end
      end

      context "when this is the game's last regular list" do
        it 'deletes the regular list and the aggregate list' do
          expect { perform }
            .to change(game.inventory_lists, :count).from(2).to(0)
        end

        it 'updates the game' do
          t = Time.zone.now + 3.days
          Timecop.freeze(t) do
            perform
            expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
          end
        end

        it 'returns a Service::NoContentResult' do
          expect(perform).to be_a(Service::NoContentResult)
        end

        it "doesn't return any data", :aggregate_failures do
          expect(perform.resource).to be_blank
          expect(perform.errors).to be_blank
        end
      end
    end

    context 'when the list is an aggregate list' do
      let!(:inventory_list) { create(:aggregate_inventory_list, game:) }

      it 'returns a Service::MethodNotAllowedResult' do
        expect(perform).to be_a(Service::MethodNotAllowedResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq ['Cannot manually delete an aggregate inventory list']
      end
    end

    context "when the list doesn't exist" do
      let(:inventory_list) { double(id: 234_234) }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.errors).to be_blank
        expect(perform.resource).to be_blank
      end
    end

    context 'when the list belongs to another user' do
      let!(:inventory_list) { create(:inventory_list) }

      it "doesn't destroy the inventory list" do
        expect { perform }
          .not_to change(InventoryList, :count)
      end

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.errors).to be_blank
        expect(perform.resource).to be_blank
      end
    end

    context 'when something unexpected goes wrong' do
      let!(:inventory_list) { create(:inventory_list, game:) }

      before { allow_any_instance_of(InventoryList).to receive(:aggregate_list).and_raise(StandardError.new('Something went horribly wrong')) }

      it 'returns a Service::InternalServerErrorResult' do
        expect(perform).to be_a(Service::InternalServerErrorResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq ['Something went horribly wrong']
      end
    end
  end
end

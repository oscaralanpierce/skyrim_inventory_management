# frozen_string_literal: true

require 'rails_helper'
require 'service/internal_server_error_result'
require 'service/method_not_allowed_result'
require 'service/not_found_result'
require 'service/ok_result'
require 'service/unprocessable_entity_result'

RSpec.describe InventoryItemsController::UpdateService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, list_item.id, params).perform }

    let(:user) { create(:user) }
    let(:game) { create(:game, user:) }
    let!(:aggregate_list) { create(:aggregate_inventory_list, game:) }
    let!(:inventory_list) { create(:inventory_list, game:, aggregate_list:) }

    context 'when all goes well' do
      context 'when there is no matching item on another list' do
        let!(:list_item) { create(:inventory_item, list: inventory_list, description: 'Dwarven metal ingot', quantity: 2) }
        let(:aggregate_list_item) { aggregate_list.list_items.first }
        let(:params) { { quantity: 9, notes: 'To make bolts with' } }

        before do
          aggregate_list.add_item_from_child_list(list_item)
        end

        it 'updates the list item', :aggregate_failures do
          perform
          expect(list_item.reload.quantity).to eq(9)
          expect(list_item.notes).to eq('To make bolts with')
        end

        it 'updates the aggregate list item quantity' do
          perform
          expect(aggregate_list_item.quantity).to eq(9)
          expect(aggregate_list_item.notes).to be_nil
        end

        it 'returns a Service::OkResult' do
          expect(perform).to be_a(Service::OkResult)
        end

        it 'returns the list item and aggregate list item as the resource' do
          expect(perform.resource).to eq([aggregate_list_item, list_item.reload])
        end
      end

      context 'when there is a matching item on another list' do
        let!(:list_item) { create(:inventory_item, list: inventory_list, quantity: 4) }
        let(:other_list) { create(:inventory_list, game:, aggregate_list:) }
        let!(:other_item) { create(:inventory_item, description: list_item.description, list: other_list, quantity: 3) }
        let(:aggregate_list_item) { aggregate_list.list_items.first }

        before do
          aggregate_list.add_item_from_child_list(list_item)
          aggregate_list.add_item_from_child_list(other_item)
        end

        context 'when the unit weight is not changed' do
          let(:params) { { quantity: 12 } }

          it 'updates the list item' do
            perform
            expect(list_item.reload.quantity).to eq(12)
          end

          it 'updates the aggregate list item' do
            perform
            expect(aggregate_list.reload.list_items.first.quantity).to eq(15)
          end

          it 'returns a Service::OkResult' do
            expect(perform).to be_a(Service::OkResult)
          end

          it 'sets the resource to the aggregate list item and the regular list item' do
            expect(perform.resource).to eq([aggregate_list_item, list_item.reload])
          end
        end

        context 'when the unit weight is changed' do
          let(:params) { { quantity: 10, unit_weight: 2 } }

          it 'updates the list item', :aggregate_failures do
            perform
            expect(list_item.reload.quantity).to eq(10)
            expect(list_item.unit_weight).to eq(2)
          end

          it 'updates the aggregate list item', :aggregate_failures do
            perform
            expect(aggregate_list_item.quantity).to eq(13)
            expect(aggregate_list_item.unit_weight).to eq(2)
          end

          it 'updates only the unit weight of the other list item', :aggregate_failures do
            perform
            expect(other_item.reload.quantity).to eq(3)
            expect(other_item.unit_weight).to eq(2)
          end

          it 'returns a Service::OkResult' do
            expect(perform).to be_a(Service::OkResult)
          end

          it 'returns all the list items that were changed' do
            expect(perform.resource).to eq([aggregate_list_item, other_item.reload, list_item.reload])
          end
        end
      end
    end

    context "when the inventory list item doesn't exist" do
      let(:list_item) { double(id: 3_459_250) }
      let(:params) { { quantity: 4 } }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it 'leaves the resource and errors empty', :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the inventory list item belongs to another user' do
      let!(:list_item) { create(:inventory_item) }
      let(:params) { { quantity: 4 } }

      it "doesn't update the item" do
        expect { perform }
          .not_to change(list_item.reload, :quantity)
      end

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it 'leaves the resource and errors empty', :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the item is on an aggregate list' do
      let!(:list_item) { create(:inventory_item, list: aggregate_list) }
      let(:params) { { quantity: 5 } }

      it 'returns a Service::MethodNotAllowedResult' do
        expect(perform).to be_a(Service::MethodNotAllowedResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq(['Cannot manually update list items on an aggregate inventory list'])
      end
    end

    context 'when the attributes are invalid' do
      let!(:list_item) { create(:inventory_item, list: inventory_list, quantity: 2) }
      let(:other_list) { create(:inventory_list, game:) }
      let!(:other_item) { create(:inventory_item, list: other_list, description: list_item.description, quantity: 1) }
      let(:aggregate_list_item) { aggregate_list.list_items.first }
      let(:params) { { quantity: -4, unit_weight: 2 } }

      before do
        aggregate_list.add_item_from_child_list(list_item)
        aggregate_list.add_item_from_child_list(other_item)
      end

      it "doesn't update the aggregate list item", :aggregate_failures do
        perform
        expect(aggregate_list_item.quantity).to eq(3)
        expect(aggregate_list_item.unit_weight).to be_nil
      end

      it "doesn't update the other item's unit_weight" do
        perform
        expect(other_item.reload.unit_weight).to be_nil
      end

      it 'returns a Service::UnprocessableEntityResult' do
        expect(perform).to be_a(Service::UnprocessableEntityResult)
      end

      it 'includes the validation errors' do
        expect(perform.errors).to eq(['Quantity must be greater than 0'])
      end
    end

    context 'when there is an unexpected error' do
      let!(:list_item) { create(:inventory_item, list: inventory_list) }
      let(:params) { { notes: 'Hello world' } }

      before do
        aggregate_list.add_item_from_child_list(list_item)
        allow_any_instance_of(InventoryList)
          .to receive(:aggregate)
                .and_raise(StandardError.new('Something went horribly wrong'))
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

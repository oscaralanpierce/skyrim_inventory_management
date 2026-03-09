# frozen_string_literal: true

require 'rails_helper'
require 'service/created_result'
require 'service/ok_result'
require 'service/not_found_result'
require 'service/method_not_allowed_result'
require 'service/internal_server_error_result'

RSpec.describe WishListItemsController::CreateService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, wish_list.id, params).perform }

    let(:user) { create(:user) }
    let(:game) { create(:game, user:) }
    let!(:aggregate_list) { create(:aggregate_wish_list, game:) }
    let!(:wish_list) { create(:wish_list, game:, aggregate_list:) }

    context 'when all goes well' do
      let(:params) { { description: 'Necklace', quantity: 2, notes: 'Hello world' } }

      context 'when there is no existing matching item on the same list' do
        context 'when there is no existing matching item on any list' do
          context 'when unit weight is not set' do
            it 'creates a new item on the list' do
              expect { perform }
                .to change(wish_list.list_items, :count).from(0).to(1)
            end

            it 'creates a new item on the aggregate list' do
              expect { perform }
                .to change(aggregate_list.list_items, :count).from(0).to(1)
            end

            it 'returns a Service::CreatedResult' do
              expect(perform).to be_a(Service::CreatedResult)
            end

            it 'sets the resource to all the changed wish lists' do
              expect(perform.resource).to eq [aggregate_list, wish_list]
            end
          end

          context 'when unit weight is set' do
            let(:params) { { description: 'Necklace', quantity: 2, unit_weight: 0.3, notes: 'Hello world' } }

            it 'creates a new item on the list' do
              expect { perform }
                .to change(wish_list.list_items, :count).from(0).to(1)
            end

            it 'creates a new item on the aggregate list' do
              expect { perform }
                .to change(aggregate_list.list_items, :count).from(0).to(1)
            end

            it 'returns a Service::CreatedResult' do
              expect(perform).to be_a(Service::CreatedResult)
            end

            it 'sets the resource to all the changed wish lists' do
              expect(perform.resource).to eq [aggregate_list, wish_list]
            end
          end
        end

        context 'when there is an existing matching item on another list' do
          let(:other_list) { create(:wish_list, game: aggregate_list.game, aggregate_list:) }
          let!(:other_item) { create(:wish_list_item, list: other_list, description: 'Necklace', unit_weight: 1, quantity: 1) }

          before do
            # This should not be included in the resource body
            create(:wish_list, game:)

            aggregate_list.add_item_from_child_list(other_item)
          end

          context 'when the unit_weight is not set' do
            it 'creates a new item on the list' do
              expect { perform }
                .to change(wish_list.list_items, :count).from(0).to eq 1
            end

            it 'sets the unit weight on the new item' do
              perform
              expect(wish_list.list_items.unscoped.last.unit_weight).to eq 1
            end

            it 'updates the item on the aggregate list', :aggregate_failures do
              perform
              expect(aggregate_list.list_items.first.unit_weight).to eq 1
              expect(aggregate_list.list_items.first.quantity).to eq 3
              expect(aggregate_list.list_items.first.notes).to be_nil
            end

            it 'returns a Service::CreatedResult' do
              expect(perform).to be_a(Service::CreatedResult)
            end

            it 'sets all the changed wish lists as the resource' do
              expect(perform.resource).to eq([aggregate_list, wish_list])
            end
          end

          context 'when the unit_weight is set' do
            let(:params) { { description: 'Necklace', quantity: 2, unit_weight: 0.5, notes: 'Hello world' } }

            it 'creates a new item on the list' do
              expect { perform }
                .to change(wish_list.list_items, :count).from(0).to(1)
            end

            it 'updates the item on the aggregate list', :aggregate_failures do
              perform
              expect(aggregate_list.list_items.first.quantity).to eq 3
              expect(aggregate_list.list_items.first.unit_weight).to eq 0.5
              expect(aggregate_list.list_items.first.notes).to be_nil
            end

            it "updates the other item's unit_weight", :aggregate_failures do
              perform
              expect(other_item.reload.quantity).to eq 1
              expect(other_item.reload.unit_weight).to eq 0.5
            end

            it 'returns a Service::CreatedResult' do
              expect(perform).to be_a(Service::CreatedResult)
            end

            it 'sets all the changed wish lists as the resource' do
              expect(perform.resource).to eq([aggregate_list, other_list, wish_list])
            end
          end
        end
      end

      context 'when there is an existing matching item on the same list' do
        let(:other_list) { create(:wish_list, game:) }
        let!(:other_item) { create(:wish_list_item, list: other_list, description: 'Necklace', quantity: 2) }
        let!(:list_item) { create(:wish_list_item, list: wish_list, description: 'Necklace', quantity: 1) }

        before do
          # This should not be included in the resource body
          create(:wish_list, game:)

          aggregate_list.add_item_from_child_list(other_item)
          aggregate_list.add_item_from_child_list(list_item)
        end

        context "when unit weight isn't updated" do
          let(:params) { { description: 'Necklace', quantity: 2 } }

          it "doesn't create a new item" do
            expect { perform }
              .not_to change(WishListItem, :count)
          end

          it 'combines with the existing item' do
            perform
            expect(list_item.reload.quantity).to eq 3
          end

          it 'updates the item on the aggregate list' do
            perform
            expect(aggregate_list.list_items.first.quantity).to eq 5
          end

          it 'returns a Service::OkResult' do
            expect(perform).to be_a(Service::OkResult)
          end

          it 'sets all the changed wish lists as the resource' do
            expect(perform.resource).to eq([aggregate_list, wish_list])
          end
        end

        context 'when unit weight is updated' do
          let(:params) { { description: 'Necklace', quantity: 2, unit_weight: 0.5 } }

          it "doesn't create a new list item" do
            expect { perform }
              .not_to change(WishListItem, :count)
          end

          it 'combines the items', :aggregate_failures do
            perform
            expect(list_item.reload.quantity).to eq 3
            expect(list_item.unit_weight).to eq 0.5
          end

          it 'updates the item on the aggregate list', :aggregate_failures do
            perform
            expect(aggregate_list.list_items.first.quantity).to eq 5
            expect(aggregate_list.list_items.first.unit_weight).to eq 0.5
          end

          it 'updates only the unit_weight on the other item', :aggregate_failures do
            perform
            expect(other_item.reload.unit_weight).to eq 0.5
            expect(other_item.quantity).to eq 2
          end

          it 'returns a Service::OkResult' do
            expect(perform).to be_a(Service::OkResult)
          end

          it 'sets all the changed wish lists as the resource' do
            expect(perform.resource).to eq([aggregate_list, other_list, wish_list])
          end
        end
      end
    end

    context "when the list doesn't exist" do
      let(:params) { { description: 'Necklace', quantity: 4, unit_weight: 0.5 } }
      let(:wish_list) { double(id: 234_980) }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the list belongs to another user' do
      let(:params) { { description: 'Necklace', quantity: 4, unit_weight: 0.5 } }
      let!(:wish_list) { create(:wish_list) }

      it "doesn't create a list item" do
        expect { perform }
          .not_to change(WishListItem, :count)
      end

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the params are invalid' do
      let(:params) { { description: 'Necklace', quantity: -2 } }

      it 'returns a Service::UnprocessableEntityResult' do
        expect(perform).to be_a(Service::UnprocessableEntityResult)
      end

      it 'returns the error array' do
        expect(perform.errors).to eq(['Quantity must be greater than 0'])
      end
    end

    context 'when the list is an aggregate list' do
      let(:wish_list) { aggregate_list }
      let!(:params) { { description: 'Necklace', quantity: 2 } }

      it "doesn't create an item" do
        expect { perform }
          .not_to change(WishListItem, :count)
      end

      it 'returns a Service::MethodNotAllowedResult' do
        expect(perform).to be_a(Service::MethodNotAllowedResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq ['Cannot manually manage items on an aggregate wish list']
      end
    end

    context 'when something unexpected goes wrong' do
      let!(:params) { { description: 'Necklace', quantity: 2 } }

      before { allow(WishList).to receive(:find).and_raise(StandardError.new('Something went horribly wrong')) }

      it 'returns a Service::InternalServerErrorResponse' do
        expect(perform).to be_a(Service::InternalServerErrorResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq ['Something went horribly wrong']
      end
    end
  end
end

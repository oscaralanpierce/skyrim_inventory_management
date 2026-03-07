# frozen_string_literal: true

require 'rails_helper'
require 'service/ok_result'
require 'service/not_found_result'
require 'service/method_not_allowed_result'
require 'service/internal_server_error_result'

RSpec.describe WishListItemsController::DestroyService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, list_item.id).perform }

    let(:game) { create(:game) }
    let!(:aggregate_list) { create(:aggregate_wish_list, game:) }
    let!(:wish_list) { create(:wish_list, game:, aggregate_list:) }

    context 'when all goes well' do
      let(:list_item) { create(:wish_list_item, list: wish_list, notes: 'some notes') }
      let(:user) { game.user }

      before do
        aggregate_list.add_item_from_child_list(list_item)
      end

      context 'when the quantity on the aggregate list equals the quantity on the regular list' do
        it 'destroys the list item' do
          perform
          expect { WishListItem.find(list_item.id) }
            .to raise_error ActiveRecord::RecordNotFound
        end

        it 'destroys the item on the aggregate list' do
          expect { perform }
            .to change(aggregate_list.list_items, :count).from(1).to(0)
        end

        it 'returns a Service::OkResult' do
          expect(perform).to be_a Service::OkResult
        end

        it 'sets the aggregate list and the regular list as the resource' do
          expect(perform.resource).to eq([aggregate_list, wish_list])
        end

        it 'sets the updated_at timestamp on the wish list' do
          t = Time.zone.now + 3.days
          Timecop.freeze(t) do
            perform
            # use `be_within` even though the time will be set to the time Timecop
            # has frozen because Rails (Postgres?) sets the last three digits of
            # the timestamp to 0, which was breaking stuff in CI (but somehow not
            # in dev).
            expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
          end
        end
      end

      context 'when the quantity on the aggregate list exceeds the quantity on the regular list' do
        let(:user) { game.user }
        let(:second_list) { create(:wish_list, game:, aggregate_list:) }
        let(:second_list_item) do
          create(:wish_list_item,
                 list: second_list,
                 description: list_item.description.upcase, # make sure comparison is case insensitive
                 quantity: 2,
                 notes: 'some other notes',)
        end

        before do
          aggregate_list.add_item_from_child_list(second_list_item)
        end

        it 'destroys the list item' do
          perform
          expect { WishListItem.find(list_item.id) }
            .to raise_error ActiveRecord::RecordNotFound
        end

        it 'changes the quantity of the aggregate list item' do
          perform
          expect(aggregate_list.list_items.first.quantity).to eq 2
        end

        it 'sets the updated_at timestamp on the wish list' do
          t = Time.zone.now + 3.days
          Timecop.freeze(t) do
            perform
            # use `be_within` even though the time will be set to the time Timecop
            # has frozen because Rails (Postgres?) sets the last three digits of
            # the timestamp to 0, which was breaking stuff in CI (but somehow not
            # in dev).
            expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
          end
        end

        it 'returns a Service::OkResult' do
          expect(perform).to be_a Service::OkResult
        end

        it 'sets the aggregate list and the regular list as the resource' do
          expect(perform.resource).to eq([aggregate_list, wish_list])
        end
      end
    end

    context "when the specified list item doesn't exist" do
      let(:user) { game.user }
      let(:list_item) { double(id: 389) }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the specified list item belongs to another user' do
      let(:user) { game.user }
      let!(:list_item) { create(:wish_list_item) }

      it "doesn't destroy the list item" do
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

    context 'when the specified list item is on an aggregate list' do
      let(:user) { list_item.user }
      let(:list_item) { create(:wish_list_item, list: aggregate_list) }

      it "doesn't destroy the list item" do
        perform
        expect(WishListItem.find(list_item.id)).to be_a WishListItem
      end

      it 'returns a Service::MethodNotAllowedResult' do
        expect(perform).to be_a Service::MethodNotAllowedResult
      end

      it 'includes a helpful error message' do
        expect(perform.errors).to eq ['Cannot manually delete list item from aggregate wish list']
      end
    end

    context 'when something unexpected goes wrong' do
      let(:user) { list_item.user }
      let(:list_item) { create(:wish_list_item, list: wish_list) }

      before do
        allow_any_instance_of(WishListItem)
          .to receive(:destroy!)
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

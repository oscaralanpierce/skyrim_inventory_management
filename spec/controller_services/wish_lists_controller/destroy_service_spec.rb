# frozen_string_literal: true

require 'rails_helper'
require 'service/method_not_allowed_result'
require 'service/not_found_result'
require 'service/ok_result'

RSpec.describe WishListsController::DestroyService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, wish_list.id).perform }

    let(:user) { create(:user) }

    context 'when all goes well' do
      let!(:wish_list) { create(:wish_list_with_list_items, game:) }
      let(:game) { create(:game, user:) }

      context 'when the game has additional regular lists' do
        let!(:third_list) { create(:wish_list_with_list_items, game:) }

        let(:expected_resource) { { deleted: [wish_list.id], aggregate: game.aggregate_wish_list } }

        before do
          wish_list.list_items.each {|list_item| game.aggregate_wish_list.add_item_from_child_list(list_item) }

          third_list.list_items.each {|list_item| game.aggregate_wish_list.add_item_from_child_list(list_item) }
        end

        it 'destroys the wish list' do
          expect { perform }
            .to change(game.wish_lists, :count).from(3).to(2)
        end

        it 'updates the game' do
          t = Time.zone.now + 3.days
          Timecop.freeze(t) do
            perform
            expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
          end
        end

        it 'returns a Service::OkResult' do
          expect(perform).to be_a(Service::OkResult)
        end

        it 'includes the deleted list ID and the aggregate list as the resource' do
          expect(perform.resource).to eq expected_resource
        end

        describe 'updating the aggregate list' do
          before do
            items = create_list(:wish_list_item, 2, list: third_list)
            items.each {|item| wish_list.aggregate_list.add_item_from_child_list(item) }

            # Because in the code it finds the wish list by ID and then gets the aggregate list
            # off that instance, the tests don't have access to the instance of the aggregate list that
            # the method is actually being called on, so we have to resort to this hack.
            user_lists = user.wish_lists
            allow(user).to receive(:wish_lists).and_return(user_lists)
            allow(user_lists).to receive(:find).and_return(wish_list)
            allow(wish_list).to receive(:aggregate_list).and_return(wish_list.aggregate_list)
            allow(wish_list.aggregate_list).to receive(:remove_item_from_child_list).twice
          end

          it 'calls #remove_item_from_child_list for each item', :aggregate_failures do
            perform

            wish_list.list_items.each {|item| expect(aggregate_list).to have_received(:remove_item_from_child_list).with(item.attributes) }
          end
        end
      end

      context "when this is the game's last regular list" do
        let(:expected_resource) { { deleted: [wish_list.aggregate_list_id, wish_list.id] } }

        before { wish_list.list_items.each {|item| game.aggregate_wish_list.add_item_from_child_list(item) } }

        it 'destroys the aggregate list too' do
          expect { perform }
            .to change(game.wish_lists, :count).from(2).to(0)
        end

        it 'updates the game' do
          t = Time.zone.now + 3.days
          Timecop.freeze(t) do
            perform
            expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
          end
        end

        it 'returns a Service::OkResult' do
          expect(perform).to be_a(Service::OkResult)
        end

        it 'returns an array of deleted list IDs as the resource' do
          expect(perform.resource).to eq expected_resource
        end
      end
    end

    context 'when the list is an aggregate list' do
      let!(:wish_list) { create(:aggregate_wish_list, game:) }
      let(:game) { create(:game, user:) }

      it 'returns a Service::MethodNotAllowedResult' do
        expect(perform).to be_a(Service::MethodNotAllowedResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq ['Cannot manually delete an aggregate wish list']
      end
    end

    context 'when the list does not exist' do
      let(:wish_list) { double('list that does not exist', id: 838) }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the list belongs to another user' do
      let!(:wish_list) { create(:wish_list) }

      it "doesn't destroy the wish list" do
        expect { perform }
          .not_to change(WishList, :count)
      end

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when something unexpected goes wrong' do
      let!(:wish_list) { create(:wish_list, game:) }
      let(:game) { create(:game, user:) }

      before { allow_any_instance_of(WishList).to receive(:aggregate_list).and_raise(StandardError.new('Something went horribly wrong')) }

      it 'returns a Service::InternalServerErrorResult' do
        expect(perform).to be_a(Service::InternalServerErrorResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq ['Something went horribly wrong']
      end
    end
  end
end

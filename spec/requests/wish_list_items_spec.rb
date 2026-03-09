# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WishListItems', type: :request do
  let(:headers) { { 'Content-Type' => 'application/json', 'Authorization' => 'Bearer xxxxxxx' } }

  describe 'POST /wish_lists/:wish_list_id/wish_list_items' do
    subject(:create_item) { post "/wish_lists/#{wish_list.id}/wish_list_items", params:, headers: }

    let!(:user) { create(:authenticated_user) }
    let(:game) { create(:game, user:) }
    let!(:aggregate_list) { create(:aggregate_wish_list, game:) }
    let!(:wish_list) { create(:wish_list, aggregate_list:, game:) }

    context 'when authenticated' do
      before { stub_successful_login }

      context 'when all goes well' do
        let(:params) { { wish_list_item: { description: 'Corundum ingot', quantity: 5, notes: 'To make locks' } }.to_json }

        context 'when there is no existing matching item on the same list' do
          context 'when there is no existing matching item on any list' do
            context 'when unit weight is not set' do
              it 'creates a new item on the requested list' do
                expect { create_item }
                  .to change(wish_list.list_items, :count).from(0).to(1)
              end

              it 'creates a new item on the aggregate list' do
                expect { create_item }
                  .to change(aggregate_list.list_items, :count).from(0).to(1)
              end

              it 'returns status 201' do
                create_item
                expect(response.status).to eq 201
              end

              it 'returns all changed wish lists for the same game' do
                create_item
                expect(response.body).to eq(game.wish_lists.to_json)
              end
            end

            context 'when unit weight is set' do
              let(:params) { { wish_list_item: { description: 'Corundum ingot', quantity: 5, notes: 'To make locks' } }.to_json }

              it 'creates a new item on the requested list' do
                expect { create_item }
                  .to change(wish_list.list_items, :count).from(0).to(1)
              end

              it 'creates a new item on the aggregate list' do
                expect { create_item }
                  .to change(aggregate_list.list_items, :count).from(0).to(1)
              end

              it 'returns status 201' do
                create_item
                expect(response.status).to eq 201
              end

              it 'returns all changed wish lists for the same game' do
                create_item
                expect(response.body).to eq(game.wish_lists.to_json)
              end
            end
          end

          context 'when there is an existing matching item on another list' do
            let(:other_list) { create(:wish_list, game:) }
            let!(:other_item) { create(:wish_list_item, list: other_list, description: 'Corundum ingot', quantity: 2) }

            before do
              # This list has nothing to do with things and should not be included in the
              # response bodies.
              create(:wish_list, game:)

              aggregate_list.add_item_from_child_list(other_item)
            end

            context "when unit weight isn't set" do
              let(:params) { { wish_list_item: { description: 'Corundum ingot', quantity: 5 } }.to_json }

              it 'creates a new item on the requested list' do
                expect { create_item }
                  .to change(wish_list.list_items, :count).from(0).to(1)
              end

              it 'updates the item on the aggregate list' do
                create_item
                expect(aggregate_list.list_items.first.quantity).to eq 7
              end

              it 'returns status 201' do
                create_item
                expect(response.status).to eq 201
              end

              it 'returns all changed wish lists from the same game' do
                create_item
                expect(response.body).to eq(game.wish_lists.where(id: [aggregate_list.id, wish_list.id]).to_json)
              end
            end

            context 'when unit weight is set' do
              let(:params) { { wish_list_item: { description: 'Corundum ingot', quantity: 5, unit_weight: 1 } }.to_json }

              it 'creates a new item on the requested list' do
                expect { create_item }
                  .to change(wish_list.list_items, :count).from(0).to(1)
              end

              it 'updates the item on the aggregate list', :aggregate_failures do
                create_item
                expect(aggregate_list.list_items.first.quantity).to eq 7
                expect(aggregate_list.list_items.first.unit_weight).to eq 1
              end

              it 'updates the unit weight of the other regular-list item', :aggregate_failures do
                create_item
                expect(other_item.reload.unit_weight).to eq 1
                expect(other_item.reload.quantity).to eq 2
              end

              it 'returns status 201' do
                create_item
                expect(response.status).to eq 201
              end

              it 'returns all changed wish lists for the same game' do
                create_item
                expect(response.body).to eq(game.wish_lists.where(id: [aggregate_list.id, wish_list.id, other_list.id]).to_json)
              end
            end
          end
        end

        context 'when there is an existing matching item on the same list' do
          let(:other_list) { create(:wish_list, game: aggregate_list.game, aggregate_list:) }
          let!(:other_item) { create(:wish_list_item, list: other_list, description: 'Corundum ingot', quantity: 2) }
          let!(:list_item) { create(:wish_list_item, list: wish_list, description: 'Corundum ingot', quantity: 3) }

          before do
            # This list has nothing to do with things and should not be included in the
            # response bodies.
            create(:wish_list, game:)

            aggregate_list.add_item_from_child_list(other_item)
            aggregate_list.add_item_from_child_list(list_item)
          end

          context "when unit weight isn't updated" do
            it "doesn't create a new item" do
              expect { create_item }
                .not_to change(WishListItem, :count)
            end

            it 'combines with the existing item' do
              create_item
              expect(list_item.reload.quantity).to eq 8
            end

            it 'updates the item on the aggregate list' do
              create_item
              expect(aggregate_list.list_items.first.quantity).to eq 10
            end

            it 'returns status 200' do
              create_item
              expect(response.status).to eq 200
            end

            it 'returns all changed wish lists for the same game' do
              create_item
              expect(response.body).to eq(game.wish_lists.where(id: [aggregate_list.id, wish_list.id]).to_json)
            end
          end

          context 'when unit weight is updated' do
            let(:params) { { wish_list_item: { description: 'Corundum ingot', quantity: 2, unit_weight: 1 } }.to_json }

            it "doesn't create a new list item" do
              expect { create_item }
                .not_to change(WishListItem, :count)
            end

            it 'combines it with the existing item', :aggregate_failures do
              create_item
              expect(list_item.reload.quantity).to eq 5
              expect(list_item.unit_weight).to eq 1
            end

            it 'updates the item on the aggregate list', :aggregate_failures do
              create_item
              expect(aggregate_list.list_items.first.quantity).to eq 7
              expect(aggregate_list.list_items.first.unit_weight).to eq 1
            end

            it 'updates only the unit_weight on the other item', :aggregate_failures do
              create_item
              expect(other_item.reload.unit_weight).to eq 1
              expect(other_item.quantity).to eq 2
            end

            it 'returns status 200' do
              create_item
              expect(response.status).to eq 200
            end

            it 'returns all changed wish lists for the same game' do
              create_item
              expect(response.body).to eq(game.wish_lists.where(id: [aggregate_list.id, wish_list.id, other_list.id]).to_json)
            end
          end
        end
      end

      context "when the list doesn't exist" do
        let(:params) { { description: 'Necklace', quantity: 2, unit_weight: 0.5 }.to_json }
        let(:wish_list) { double(id: 23_498) }

        it 'returns status 404' do
          create_item
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          create_item
          expect(response.body).to be_blank
        end
      end

      context 'when the list belongs to another user' do
        let(:params) { { description: 'Necklace', quantity: 2, unit_weight: 0.5 }.to_json }
        let!(:wish_list) { create(:wish_list) }

        it "doesn't create a list item" do
          expect { create_item }
            .not_to change(WishListItem, :count)
        end

        it 'returns status 404' do
          create_item
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          create_item
          expect(response.body).to be_blank
        end
      end

      context 'when the params are invalid' do
        let(:params) { { wish_list_item: { description: 'Corundum ingot', quantity: -2 } }.to_json }

        it "doesn't create the item" do
          expect { create_item }
            .not_to change(WishListItem, :count)
        end

        it 'returns status 422' do
          create_item
          expect(response.status).to eq 422
        end

        it 'returns the error array' do
          create_item
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Quantity must be greater than 0'] })
        end
      end

      context 'when the list is an aggregate list' do
        let(:wish_list) { aggregate_list }
        let(:params) { { wish_list_item: { description: 'Corundum ingot', quantity: 4 } }.to_json }

        it "doesn't create an item" do
          expect { create_item }
            .not_to change(WishListItem, :count)
        end

        it 'returns status 405' do
          create_item
          expect(response.status).to eq 405
        end

        it 'returns the error' do
          create_item
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot manually manage items on an aggregate wish list'] })
        end
      end

      context 'when something unexpected goes wrong' do
        let(:params) { { wish_list_item: { description: 'Corundum ingot', quantity: 4 } }.to_json }

        before { allow(WishList).to receive(:find).and_raise(StandardError.new('Something went horribly wrong')) }

        it 'returns status 500' do
          create_item
          expect(response.status).to eq 500
        end

        it 'returns the error' do
          create_item
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Something went horribly wrong'] })
        end
      end
    end

    context 'when unauthenticated' do
      let(:params) { { wish_list_item: { description: 'Dwarven Metal Ingot', quantity: 1 } } }

      before { stub_unsuccessful_login }

      it "doesn't create a wish list item" do
        expect { create_item }
          .not_to change(WishListItem, :count)
      end

      it 'returns status 401' do
        create_item
        expect(response.status).to eq 401
      end

      it "doesn't return any data" do
        create_item
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'PATCH /wish_list_items/:id' do
    subject(:update_item) { patch "/wish_list_items/#{list_item.id}", headers:, params: }

    let!(:user) { create(:authenticated_user) }
    let(:game) { create(:game, user:) }
    let!(:aggregate_list) { create(:aggregate_wish_list, game:) }
    let!(:wish_list) { create(:wish_list, game:, aggregate_list:) }

    context 'when authenticated' do
      before { stub_successful_login }

      context 'when all goes well' do
        context 'when there is no matching item on another list' do
          let!(:list_item) { create(:wish_list_item, list: wish_list, description: 'Dwarven metal ingot', quantity: 5) }
          let(:aggregate_list_item) { aggregate_list.list_items.first }
          let(:params) { { wish_list_item: { description: 'Dwarven metal ingot', quantity: 10 } }.to_json }

          before { aggregate_list.add_item_from_child_list(list_item) }

          it 'updates the list item' do
            update_item
            expect(list_item.reload.quantity).to eq 10
          end

          it 'updates the aggregate list item' do
            update_item
            expect(aggregate_list_item.quantity).to eq 10
          end

          it 'updates the regular list' do
            t = Time.zone.now + 3.days
            Timecop.freeze(t) do
              update_item
              expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
            end
          end

          it 'updates the aggregate list' do
            t = Time.zone.now + 3.days
            Timecop.freeze(t) do
              update_item
              expect(aggregate_list.reload.updated_at).to be_within(0.005.seconds).of(t)
            end
          end

          it 'updates the game' do
            t = Time.zone.now + 3.days
            Timecop.freeze(t) do
              update_item
              expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
            end
          end

          it 'returns status 200' do
            update_item
            expect(response.status).to eq 200
          end

          it 'returns the modified wish list items' do
            update_item
            expect(response.body).to eq([aggregate_list_item, list_item.reload].to_json)
          end
        end

        context 'when there is a matching item on another list' do
          let!(:list_item) { create(:wish_list_item, list: wish_list, unit_weight: 1) }
          let!(:other_list) { create(:wish_list, game:, aggregate_list:) }
          let!(:other_item) { create(:wish_list_item, list: other_list, description: list_item.description, quantity: 4, unit_weight: 1) }
          let(:aggregate_list_item) { aggregate_list.list_items.first }

          before do
            aggregate_list.add_item_from_child_list(list_item)
            aggregate_list.add_item_from_child_list(other_item)
          end

          context 'when unit_weight is not changed' do
            let(:params) { { wish_list_item: { quantity: 10 } }.to_json }

            it 'updates the list item' do
              update_item
              expect(list_item.reload.quantity).to eq 10
            end

            it 'updates the aggregate list item' do
              update_item
              expect(aggregate_list_item.quantity).to eq 14
            end

            it 'updates the regular list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the aggregate list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(aggregate_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the game' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'returns status 200' do
              update_item
              expect(response.status).to eq 200
            end

            it 'returns the two modified list items' do
              update_item
              expect(response.body).to eq([aggregate_list_item, list_item.reload].to_json)
            end
          end

          context 'when unit_weight is changed' do
            let(:params) { { wish_list_item: { quantity: 10, unit_weight: 2 } }.to_json }

            it 'updates the list item', :aggregate_failures do
              update_item
              expect(list_item.reload.quantity).to eq 10
              expect(list_item.unit_weight).to eq 2
            end

            it 'updates the aggregate list item', :aggregate_failures do
              update_item
              expect(aggregate_list_item.quantity).to eq 14
              expect(aggregate_list_item.unit_weight).to eq 2
            end

            it 'updates only the unit weight of the other list item', :aggregate_failures do
              update_item
              expect(other_item.reload.quantity).to eq 4
              expect(other_item.unit_weight).to eq 2
            end

            it 'updates the regular list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the aggregate list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(aggregate_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the other list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(other_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the game' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'returns status 200' do
              update_item
              expect(response.status).to eq 200
            end

            it 'returns all the modified list items' do
              update_item
              expect(response.body).to eq([aggregate_list_item, other_item.reload, list_item.reload].to_json)
            end
          end

          context 'when unit_weight is set to nil' do
            let(:params) { { wish_list_item: { quantity: 10, unit_weight: nil } }.to_json }

            it 'updates the list item', :aggregate_failures do
              update_item
              expect(list_item.reload.quantity).to eq 10
              expect(list_item.unit_weight).to be_nil
            end

            it 'updates the aggregate list item', :aggregate_failures do
              update_item
              expect(aggregate_list_item.quantity).to eq 14
              expect(aggregate_list_item.unit_weight).to be_nil
            end

            it 'updates only the unit weight of the other list item', :aggregate_failures do
              update_item
              expect(other_item.reload.quantity).to eq 4
              expect(other_item.unit_weight).to be_nil
            end

            it 'updates the regular list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the aggregate list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(aggregate_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the other list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(other_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the game' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'returns status 200' do
              update_item
              expect(response.status).to eq 200
            end

            it 'returns all the modified list items' do
              update_item
              expect(response.body).to eq([aggregate_list_item, other_item.reload, list_item.reload].to_json)
            end
          end
        end
      end

      context "when the wish list item doesn't exist" do
        let(:list_item) { double(id: 234_567) }
        let(:params) { { quantity: 4, unit_weight: 0.3 }.to_json }

        it 'returns status 404' do
          update_item
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          update_item
          expect(response.body).to be_blank
        end
      end

      context 'when the wish list item belongs to another user' do
        let!(:list_item) { create(:wish_list_item) }
        let(:params) { { quantity: 4, unit_weight: 0.3 }.to_json }

        it "doesn't update the item" do
          expect { update_item }
            .not_to change(list_item.reload, :attributes)
        end

        it 'returns status 404' do
          update_item
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          update_item
          expect(response.body).to be_blank
        end
      end

      context 'when the list item is on an aggregate list' do
        let!(:list_item) { create(:wish_list_item, list: aggregate_list) }
        let(:params) { { wish_list_item: { quantity: 10 } }.to_json }

        it 'returns status 405' do
          update_item
          expect(response.status).to eq 405
        end

        it 'returns an error array' do
          update_item
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot manually update list items on an aggregate wish list'] })
        end
      end

      context 'when the attributes are invalid' do
        let!(:list_item) { create(:wish_list_item, list: wish_list, quantity: 2) }
        let(:other_list) { create(:wish_list, game:) }
        let!(:other_item) { create(:wish_list_item, list: other_list, description: list_item.description, quantity: 1) }
        let(:aggregate_list_item) { aggregate_list.list_items.first }
        let(:params) { { wish_list_item: { quantity: -4, unit_weight: 2 } }.to_json }

        before do
          aggregate_list.add_item_from_child_list(list_item)
          aggregate_list.add_item_from_child_list(other_item)
        end

        it "doesn't update the aggregate list item", :aggregate_failures do
          update_item
          expect(aggregate_list_item.quantity).to eq 3
          expect(aggregate_list_item.unit_weight).to be nil
        end

        it "doesn't update the unit weight of the other list item" do
          update_item
          expect(other_item.reload.unit_weight).to be nil
        end

        it 'returns status 422' do
          update_item
          expect(response.status).to eq 422
        end

        it 'returns the errors in an array' do
          update_item
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Quantity must be greater than 0'] })
        end
      end

      context 'when something unexpected goes wrong' do
        let!(:list_item) { create(:wish_list_item, list: wish_list) }
        let(:params) { { notes: 'Hello world' }.to_json }

        before do
          aggregate_list.add_item_from_child_list(list_item)
          allow_any_instance_of(WishList).to receive(:aggregate).and_raise(StandardError.new('Something went horribly wrong'))
        end

        it 'returns status 500' do
          update_item
          expect(response.status).to eq 500
        end

        it 'returns the error array' do
          update_item
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Something went horribly wrong'] })
        end
      end
    end

    context 'when unauthenticated' do
      let!(:list_item) { create(:wish_list_item, list: wish_list) }
      let(:params) { { wish_list_item: { quantity: 16 } } }

      before { stub_unsuccessful_login }

      it "doesn't update the wish list item" do
        expect { update_item }
          .not_to change(list_item.reload, :quantity)
      end

      it 'returns status 401' do
        update_item
        expect(response.status).to eq 401
      end

      it "doesn't return any data" do
        update_item
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'PUT /wish_list_items/:id' do
    subject(:update_item) { put "/wish_list_items/#{list_item.id}", headers:, params: }

    let!(:user) { create(:authenticated_user) }
    let(:game) { create(:game, user:) }
    let!(:aggregate_list) { create(:aggregate_wish_list, game:) }
    let!(:wish_list) { create(:wish_list, game:, aggregate_list:) }

    context 'when authenticated' do
      before { stub_successful_login }

      context 'when all goes well' do
        context 'when there is no matching item on another list' do
          let!(:list_item) { create(:wish_list_item, list: wish_list, description: 'Dwarven metal ingot', quantity: 5) }
          let(:aggregate_list_item) { aggregate_list.list_items.first }
          let(:params) { { wish_list_item: { description: 'Dwarven metal ingot', quantity: 10 } }.to_json }

          before { aggregate_list.add_item_from_child_list(list_item) }

          it 'updates the list item' do
            update_item
            expect(list_item.reload.quantity).to eq 10
          end

          it 'updates the aggregate list item' do
            update_item
            expect(aggregate_list_item.quantity).to eq 10
          end

          it 'updates the regular list' do
            t = Time.zone.now + 3.days
            Timecop.freeze(t) do
              update_item
              expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
            end
          end

          it 'updates the aggregate list' do
            t = Time.zone.now + 3.days
            Timecop.freeze(t) do
              update_item
              expect(aggregate_list.reload.updated_at).to be_within(0.005.seconds).of(t)
            end
          end

          it 'updates the game' do
            t = Time.zone.now + 3.days
            Timecop.freeze(t) do
              update_item
              expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
            end
          end

          it 'returns status 200' do
            update_item
            expect(response.status).to eq 200
          end

          it 'returns the modified wish list items' do
            update_item
            expect(response.body).to eq([aggregate_list_item, list_item.reload].to_json)
          end
        end

        context 'when there is a matching item on another list' do
          let!(:list_item) { create(:wish_list_item, list: wish_list, unit_weight: 1) }
          let!(:other_list) { create(:wish_list, game:, aggregate_list:) }
          let!(:other_item) { create(:wish_list_item, list: other_list, description: list_item.description, quantity: 4, unit_weight: 1) }
          let(:aggregate_list_item) { aggregate_list.list_items.first }

          before do
            aggregate_list.add_item_from_child_list(list_item)
            aggregate_list.add_item_from_child_list(other_item)
          end

          context 'when unit_weight is not changed' do
            let(:params) { { wish_list_item: { quantity: 10 } }.to_json }

            it 'updates the list item' do
              update_item
              expect(list_item.reload.quantity).to eq 10
            end

            it 'updates the aggregate list item' do
              update_item
              expect(aggregate_list_item.quantity).to eq 14
            end

            it 'updates the regular list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the aggregate list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(aggregate_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the game' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'returns status 200' do
              update_item
              expect(response.status).to eq 200
            end

            it 'returns the two modified list items' do
              update_item
              expect(response.body).to eq([aggregate_list_item, list_item.reload].to_json)
            end
          end

          context 'when unit_weight is changed' do
            let(:params) { { wish_list_item: { quantity: 10, unit_weight: 2 } }.to_json }

            it 'updates the list item', :aggregate_failures do
              update_item
              expect(list_item.reload.quantity).to eq 10
              expect(list_item.unit_weight).to eq 2
            end

            it 'updates the aggregate list item', :aggregate_failures do
              update_item
              expect(aggregate_list_item.quantity).to eq 14
              expect(aggregate_list_item.unit_weight).to eq 2
            end

            it 'updates only the unit weight of the other list item', :aggregate_failures do
              update_item
              expect(other_item.reload.quantity).to eq 4
              expect(other_item.unit_weight).to eq 2
            end

            it 'updates the regular list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the aggregate list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(aggregate_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the other list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(other_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the game' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'returns status 200' do
              update_item
              expect(response.status).to eq 200
            end

            it 'returns all the modified list items' do
              update_item
              expect(response.body).to eq([aggregate_list_item, other_item.reload, list_item.reload].to_json)
            end
          end

          context 'when unit_weight is set to nil' do
            let(:params) { { wish_list_item: { quantity: 10, unit_weight: nil } }.to_json }

            it 'updates the list item', :aggregate_failures do
              update_item
              expect(list_item.reload.quantity).to eq 10
              expect(list_item.unit_weight).to be_nil
            end

            it 'updates the aggregate list item', :aggregate_failures do
              update_item
              expect(aggregate_list_item.quantity).to eq 14
              expect(aggregate_list_item.unit_weight).to be_nil
            end

            it 'updates only the unit weight of the other list item', :aggregate_failures do
              update_item
              expect(other_item.reload.quantity).to eq 4
              expect(other_item.unit_weight).to be_nil
            end

            it 'updates the regular list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the aggregate list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(aggregate_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the other list' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(other_list.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'updates the game' do
              t = Time.zone.now + 3.days
              Timecop.freeze(t) do
                update_item
                expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
              end
            end

            it 'returns status 200' do
              update_item
              expect(response.status).to eq 200
            end

            it 'returns all the modified list items' do
              update_item
              expect(response.body).to eq([aggregate_list_item, other_item.reload, list_item.reload].to_json)
            end
          end
        end
      end

      context "when the wish list item doesn't exist" do
        let(:list_item) { double(id: 234_567) }
        let(:params) { { quantity: 4, unit_weight: 0.3 }.to_json }

        it 'returns status 404' do
          update_item
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          update_item
          expect(response.body).to be_blank
        end
      end

      context 'when the wish list item belongs to another user' do
        let!(:list_item) { create(:wish_list_item) }
        let(:params) { { quantity: 4, unit_weight: 0.3 }.to_json }

        it "doesn't update the item" do
          expect { update_item }
            .not_to change(list_item.reload, :attributes)
        end

        it 'returns status 404' do
          update_item
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          update_item
          expect(response.body).to be_blank
        end
      end

      context 'when the list item is on an aggregate list' do
        let!(:list_item) { create(:wish_list_item, list: aggregate_list) }
        let(:params) { { wish_list_item: { quantity: 10 } }.to_json }

        it 'returns status 405' do
          update_item
          expect(response.status).to eq 405
        end

        it 'returns an error array' do
          update_item
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot manually update list items on an aggregate wish list'] })
        end
      end

      context 'when the attributes are invalid' do
        let!(:list_item) { create(:wish_list_item, list: wish_list, quantity: 2) }
        let(:other_list) { create(:wish_list, game:) }
        let!(:other_item) { create(:wish_list_item, list: other_list, description: list_item.description, quantity: 1) }
        let(:aggregate_list_item) { aggregate_list.list_items.first }
        let(:params) { { wish_list_item: { quantity: -4, unit_weight: 2 } }.to_json }

        before do
          aggregate_list.add_item_from_child_list(list_item)
          aggregate_list.add_item_from_child_list(other_item)
        end

        it "doesn't update the aggregate list item", :aggregate_failures do
          update_item
          expect(aggregate_list_item.quantity).to eq 3
          expect(aggregate_list_item.unit_weight).to be nil
        end

        it "doesn't update the unit weight of the other list item" do
          update_item
          expect(other_item.reload.unit_weight).to be nil
        end

        it 'returns status 422' do
          update_item
          expect(response.status).to eq 422
        end

        it 'returns the errors in an array' do
          update_item
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Quantity must be greater than 0'] })
        end
      end

      context 'when something unexpected goes wrong' do
        let!(:list_item) { create(:wish_list_item, list: wish_list) }
        let(:params) { { notes: 'Hello world' }.to_json }

        before do
          aggregate_list.add_item_from_child_list(list_item)
          allow_any_instance_of(WishList).to receive(:aggregate).and_raise(StandardError.new('Something went horribly wrong'))
        end

        it 'returns status 500' do
          update_item
          expect(response.status).to eq 500
        end

        it 'returns the error array' do
          update_item
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Something went horribly wrong'] })
        end
      end
    end

    context 'when unauthenticated' do
      let!(:list_item) { create(:wish_list_item, list: wish_list) }
      let(:params) { { wish_list_item: { quantity: 16 } } }

      before { stub_unsuccessful_login }

      it "doesn't update the wish list item" do
        expect { update_item }
          .not_to change(list_item.reload, :quantity)
      end

      it 'returns status 401' do
        update_item
        expect(response.status).to eq 401
      end

      it "doesn't return any data" do
        update_item
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'DELETE /wish_list_items/:id' do
    subject(:destroy_item) { delete "/wish_list_items/#{list_item.id}", headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }
      let!(:aggregate_list) { create(:aggregate_wish_list, game:) }
      let!(:wish_list) { create(:wish_list, game:, aggregate_list:) }
      let(:game) { create(:game, user:) }

      before { stub_successful_login }

      context 'when all goes well' do
        let(:list_item) { create(:wish_list_item, list: wish_list, quantity: 3, notes: 'foo') }

        before { aggregate_list.add_item_from_child_list(list_item) }

        context 'when the quantity on the regular list equals that on the aggregate list' do
          it 'destroys the item on the regular list' do
            destroy_item
            expect { WishListItem.find(list_item.id) }
              .to raise_error ActiveRecord::RecordNotFound
          end

          it 'destroys the item on the aggregate list' do
            destroy_item
            expect(aggregate_list.list_items).to be_empty
          end

          it 'updates the regular list' do
            t = Time.zone.now + 3.days
            Timecop.freeze(t) do
              destroy_item
              expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
            end
          end

          it 'updates the aggregate list' do
            t = Time.zone.now + 3.days
            Timecop.freeze(t) do
              destroy_item
              expect(aggregate_list.reload.updated_at).to be_within(0.005.seconds).of(t)
            end
          end

          it 'updates the game' do
            t = Time.zone.now + 3.days
            Timecop.freeze(t) do
              destroy_item
              expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
            end
          end

          it 'returns status 200' do
            destroy_item
            expect(response.status).to eq 200
          end

          it 'returns the aggregate list and the regular list' do
            destroy_item
            expect(response.body).to eq([aggregate_list.reload, wish_list.reload].to_json)
          end
        end

        context 'when the quantity on the aggregate list exceeds that on the regular list' do
          let(:second_list) { create(:wish_list, game:) }

          let(:second_item) { create(:wish_list_item, list: second_list, description: list_item.description, quantity: 2, notes: 'bar') }

          before { aggregate_list.add_item_from_child_list(second_item) }

          it 'destroys the item on the regular list' do
            destroy_item
            expect { WishListItem.find(list_item.id) }
              .to raise_error ActiveRecord::RecordNotFound
          end

          it 'updates the quantity of the item on the aggregate list' do
            destroy_item
            expect(aggregate_list.list_items.first.quantity).to eq 2
          end

          it 'updates the regular list' do
            t = Time.zone.now + 3.days
            Timecop.freeze(t) do
              destroy_item
              expect(wish_list.reload.updated_at).to be_within(0.005.seconds).of(t)
            end
          end

          it 'updates the aggregate list' do
            t = Time.zone.now + 3.days
            Timecop.freeze(t) do
              destroy_item
              expect(aggregate_list.reload.updated_at).to be_within(0.005.seconds).of(t)
            end
          end

          it 'updates the game' do
            t = Time.zone.now + 3.days
            Timecop.freeze(t) do
              destroy_item
              expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
            end
          end

          it 'returns status 200' do
            destroy_item
            expect(response.status).to eq 200
          end

          it 'returns the aggregate list and the regular list' do
            destroy_item
            expect(response.body).to eq([aggregate_list.reload, wish_list.reload].to_json)
          end
        end
      end

      context "when the specified list item doesn't exist" do
        let(:list_item) { double("this doesn't exist", id: 772) }

        it 'returns status 404' do
          destroy_item
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          destroy_item
          expect(response.body).to be_blank
        end
      end

      context 'when the specified list item belongs to another user' do
        let!(:list_item) { create(:wish_list_item) }

        it "doesn't destroy the item" do
          expect { destroy_item }
            .not_to change(WishListItem, :count)
        end

        it 'returns status 404' do
          destroy_item
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          destroy_item
          expect(response.body).to be_blank
        end
      end

      context 'when the specified list item is on an aggregate list' do
        let(:list_item) { create(:wish_list_item, list: aggregate_list) }

        it 'returns status 405' do
          destroy_item
          expect(response.status).to eq 405
        end

        it 'returns a helpful error message' do
          destroy_item
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot manually delete list item from aggregate wish list'] })
        end
      end

      context 'when something unexpected goes wrong' do
        let!(:list_item) { create(:wish_list_item, list: wish_list) }

        before { allow_any_instance_of(WishList).to receive(:aggregate).and_raise(StandardError.new('Something went horribly wrong')) }

        it 'returns status 500' do
          destroy_item
          expect(response.status).to eq 500
        end

        it 'returns the error' do
          destroy_item
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Something went horribly wrong'] })
        end
      end
    end

    context 'when unauthenticated' do
      let!(:list_item) { create(:wish_list_item) }

      before { stub_unsuccessful_login }

      it "doesn't destroy the list item" do
        expect { destroy_item }
          .not_to change(WishListItem, :count)
      end

      it 'returns status 401' do
        destroy_item
        expect(response.status).to eq 401
      end

      it "doesn't return any data" do
        destroy_item
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end
end

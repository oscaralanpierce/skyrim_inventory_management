# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'InventoryLists', type: :request do
  let(:headers) { { 'Content-Type' => 'application/json', 'Authorization' => 'Bearer xxxxxxx' } }

  describe 'GET /games/:game_id/inventory_lists' do
    subject(:get_index) { get "/games/#{game.id}/inventory_lists", headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before { stub_successful_login }

      context 'when the game is not found' do
        let(:game) { double(id: 491_349_759) }

        it 'returns status 404' do
          get_index
          expect(response.status).to eq 404
        end

        it 'returns no data' do
          get_index
          expect(response.body).to be_empty
        end
      end

      context 'when the game belongs to another user' do
        let(:game) { create(:game) }

        it 'returns status 404' do
          get_index
          expect(response.status).to eq 404
        end

        it 'returns no data' do
          get_index
          expect(response.body).to be_empty
        end
      end

      context 'when there are no inventory lists for that game' do
        let(:game) { create(:game, user:) }

        it 'returns status 200' do
          get_index
          expect(response.status).to eq 200
        end

        it 'returns an empty array' do
          get_index
          expect(JSON.parse(response.body)).to eq []
        end
      end

      context 'when there are inventory lists for that game' do
        let(:game) { create(:game_with_inventory_lists, user:) }

        it 'returns status 200' do
          get_index
          expect(response.status).to eq 200
        end

        it 'returns the inventory lists in index order' do
          get_index
          expect(response.body).to eq game.inventory_lists.index_order.to_json
        end
      end
    end

    context 'when unauthenticated' do
      let!(:game) { create(:game) }

      before { stub_unsuccessful_login }

      it 'returns status 401' do
        get_index
        expect(response.status).to eq 401
      end

      it "doesn't return any data" do
        get_index
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'POST games/:game_id/inventory_lists' do
    subject(:create_inventory_list) { post "/games/#{game.id}/inventory_lists", params: { inventory_list: {} }.to_json, headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before { stub_successful_login }

      context 'when all goes well' do
        let(:game) { create(:game, user:) }

        context 'when an aggregate list has also been created' do
          it 'creates a new inventory list' do
            expect { create_inventory_list }
              .to change(game.inventory_lists, :count).from(0).to(2) # because of the aggregate list
          end

          it 'returns the aggregate list as well as the new list' do
            create_inventory_list
            expect(response.body).to eq([game.aggregate_inventory_list, game.inventory_lists.last].to_json)
          end

          it 'returns status 201' do
            create_inventory_list
            expect(response.status).to eq 201
          end
        end

        context 'when only the new inventory list has been created' do
          let!(:aggregate_list) { create(:aggregate_inventory_list, game:, created_at: 2.seconds.ago, updated_at: 2.seconds.ago) }

          it 'creates one list' do
            expect { create_inventory_list }
              .to change(game.inventory_lists, :count).from(1).to(2)
          end

          it 'returns only the newly created list' do
            create_inventory_list
            expect(response.body).to eq(game.inventory_lists.last.to_json)
          end
        end

        context 'when the request does not include a body' do
          subject(:create_inventory_list) { post "/games/#{game.id}/inventory_lists", headers: }

          before do
            # let's not have this request create an aggregate list too
            create(:aggregate_inventory_list, game:)
          end

          it 'returns status 201' do
            create_inventory_list
            expect(response.status).to eq 201
          end

          it 'creates the inventory list with a default title' do
            create_inventory_list
            list_attributes = JSON.parse(response.body)
            expect(list_attributes['title']).to eq 'My List 1'
          end
        end
      end

      context 'when the game is not found' do
        let(:game) { double(id: 84_968_294) }

        it 'returns status 404' do
          create_inventory_list
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          create_inventory_list
          expect(response.body).to be_empty
        end
      end

      context 'when the game belongs to another user' do
        let!(:game) { create(:game) }

        it "doesn't create an inventory list" do
          expect { create_inventory_list }
            .not_to change(InventoryList, :count)
        end

        it 'returns status 404' do
          create_inventory_list
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          create_inventory_list
          expect(response.body).to be_empty
        end
      end

      context 'when the params are invalid' do
        subject(:create_inventory_list) { post "/games/#{game.id}/inventory_lists", params: { inventory_list: { title: existing_list.title } }.to_json, headers: }

        let(:game) { create(:game, user:) }
        let(:existing_list) { create(:inventory_list, game:) }

        it 'returns status 422' do
          create_inventory_list
          expect(response.status).to eq 422
        end

        it 'returns the errors' do
          create_inventory_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Title must be unique per game'] })
        end
      end

      context 'when the client attempts to create an aggregate list' do
        subject(:create_inventory_list) { post "/games/#{game.id}/inventory_lists", params: { inventory_list: { aggregate: true } }.to_json, headers: }

        let(:game) { create(:game, user:) }

        it "doesn't create a list" do
          expect { create_inventory_list }
            .not_to change(game.inventory_lists, :count)
        end

        it 'returns an error' do
          create_inventory_list
          expect(response.status).to eq 422
        end

        it 'returns a helpful error body' do
          create_inventory_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot manually create an aggregate inventory list'] })
        end
      end
    end

    context 'when unauthenticated' do
      let!(:game) { create(:game) }

      before { stub_unsuccessful_login }

      it "doesn't create inventory lists" do
        expect { create_inventory_list }
          .not_to change(InventoryList, :count)
      end

      it 'returns status 401' do
        create_inventory_list
        expect(response.status).to eq 401
      end

      it "doesn't include any data" do
        create_inventory_list
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'PATCH /inventory_lists/:id' do
    subject(:update_inventory_list) { patch "/inventory_lists/#{list_id}", params: { inventory_list: { title: 'Severin Manor' } }.to_json, headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before { stub_successful_login }

      context 'when all goes well' do
        let!(:inventory_list) { create(:inventory_list, game:) }
        let(:game) { create(:game, user:) }
        let(:list_id) { inventory_list.id }

        it 'updates the title' do
          update_inventory_list
          expect(inventory_list.reload.title).to eq 'Severin Manor'
        end

        it 'returns the updated list' do
          update_inventory_list
          # This ugly hack is needed because if we don't parse the JSON, it'll make an error
          # if everything isn't in the exact same order, but if we just use inventory_list.attributes
          # it won't include the list_items. Ugly.
          expect(JSON.parse(response.body)).to eq(JSON.parse(inventory_list.reload.to_json))
        end

        it 'returns status 200' do
          update_inventory_list
          expect(response.status).to eq 200
        end
      end

      context 'when the params are invalid' do
        subject(:update_inventory_list) { patch "/inventory_lists/#{list_id}", params: { inventory_list: { title: other_list.title } }.to_json, headers: }

        let!(:inventory_list) { create(:inventory_list, game:) }
        let(:game) { create(:game, user:) }
        let(:list_id) { inventory_list.id }
        let(:other_list) { create(:inventory_list, game:) }

        it 'returns status 422' do
          update_inventory_list
          expect(response.status).to eq 422
        end

        it 'returns the errors' do
          update_inventory_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Title must be unique per game'] })
        end
      end

      context 'when the list does not exist' do
        let(:list_id) { 245_285 }

        it 'returns status 404' do
          update_inventory_list
          expect(response.status).to eq 404
        end

        it "doesn't return data" do
          update_inventory_list
          expect(response.body).to be_blank
        end
      end

      context 'when the list belongs to another user' do
        let!(:inventory_list) { create(:inventory_list) }
        let(:list_id) { inventory_list.id }

        it "doesn't update the inventory list" do
          expect { update_inventory_list }
            .not_to change(inventory_list.reload, :title)
        end

        it 'returns status 404' do
          update_inventory_list
          expect(response.status).to eq 404
        end

        it "doesn't return data" do
          update_inventory_list
          expect(response.body).to be_blank
        end
      end

      context 'when the client attempts to update an aggregate list' do
        subject(:update_inventory_list) { patch "/inventory_lists/#{inventory_list.id}", params: { inventory_list: { title: 'Foo' } }.to_json, headers: }

        let!(:inventory_list) { create(:aggregate_inventory_list, game:) }
        let(:game) { create(:game, user:) }

        it "doesn't update the list" do
          update_inventory_list
          expect(inventory_list.reload.title).to eq 'All Items'
        end

        it 'returns status 405 (method not allowed)' do
          update_inventory_list
          expect(response.status).to eq 405
        end

        it 'returns a helpful error body' do
          update_inventory_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot manually update an aggregate inventory list'] })
        end
      end

      context 'when the client attempts to change a regular list to an aggregate list' do
        subject(:update_inventory_list) { patch "/inventory_lists/#{inventory_list.id}", params: { inventory_list: { aggregate: true } }.to_json, headers: }

        let!(:inventory_list) { create(:inventory_list, game:) }
        let(:game) { create(:game, user:) }

        it "doesn't update the list" do
          update_inventory_list
          expect(inventory_list.reload.aggregate).to eq false
        end

        it 'returns status 422' do
          update_inventory_list
          expect(response.status).to eq 422
        end

        it 'returns a helpful error body' do
          update_inventory_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot make a regular inventory list an aggregate list'] })
        end
      end

      context 'when something unexpected goes wrong' do
        subject(:update_inventory_list) { patch "/inventory_lists/#{inventory_list.id}", params: { inventory_list: { title: 'Some New Title' } }.to_json, headers: }

        let!(:inventory_list) { create(:inventory_list, game:) }
        let(:game) { create(:game, user:) }

        before { allow_any_instance_of(User).to receive(:inventory_lists).and_raise(StandardError, 'Something went catastrophically wrong') }

        it 'returns status 500' do
          update_inventory_list
          expect(response.status).to eq 500
        end

        it 'returns the error in the body' do
          update_inventory_list
          expect(response.body).to eq({ errors: ['Something went catastrophically wrong'] }.to_json)
        end
      end
    end

    context 'when unauthenticated' do
      let!(:inventory_list) { create(:inventory_list) }
      let(:list_id) { inventory_list.id }

      before { stub_unsuccessful_login }

      it "doesn't update the inventory list" do
        expect { update_inventory_list }
          .not_to change(inventory_list.reload, :title)
      end

      it 'returns status 401' do
        update_inventory_list
        expect(response.status).to eq 401
      end

      it "doesn't return any data" do
        update_inventory_list
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'PUT /inventory_lists/:id' do
    subject(:update_inventory_list) { put "/inventory_lists/#{list_id}", params: { inventory_list: { title: 'Severin Manor' } }.to_json, headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before { stub_successful_login }

      context 'when all goes well' do
        let!(:inventory_list) { create(:inventory_list, game:) }
        let(:game) { create(:game, user:) }
        let(:list_id) { inventory_list.id }

        it 'updates the title' do
          update_inventory_list
          expect(inventory_list.reload.title).to eq 'Severin Manor'
        end

        it 'returns the updated list' do
          update_inventory_list
          # This ugly hack is needed because if we don't parse the JSON, it'll make an error
          # if everything isn't in the exact same order, but if we just use inventory_list.attributes
          # it won't include the list_items. Ugly.
          expect(JSON.parse(response.body)).to eq(JSON.parse(inventory_list.reload.to_json))
        end

        it 'returns status 200' do
          update_inventory_list
          expect(response.status).to eq 200
        end
      end

      context 'when the params are invalid' do
        subject(:update_inventory_list) { put "/inventory_lists/#{list_id}", params: { inventory_list: { title: other_list.title } }.to_json, headers: }

        let!(:inventory_list) { create(:inventory_list, game:) }
        let(:game) { create(:game, user:) }
        let(:list_id) { inventory_list.id }
        let(:other_list) { create(:inventory_list, game:) }

        it 'returns status 422' do
          update_inventory_list
          expect(response.status).to eq 422
        end

        it 'returns the errors' do
          update_inventory_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Title must be unique per game'] })
        end
      end

      context 'when the list does not exist' do
        let(:list_id) { 245_285 }

        it 'returns status 404' do
          update_inventory_list
          expect(response.status).to eq 404
        end

        it "doesn't return data" do
          update_inventory_list
          expect(response.body).to be_blank
        end
      end

      context 'when the list belongs to another user' do
        let!(:inventory_list) { create(:inventory_list) }
        let(:list_id) { inventory_list.id }

        it "doesn't update the inventory list" do
          expect { update_inventory_list }
            .not_to change(inventory_list.reload, :title)
        end

        it 'returns status 404' do
          update_inventory_list
          expect(response.status).to eq 404
        end

        it "doesn't return data" do
          update_inventory_list
          expect(response.body).to be_blank
        end
      end

      context 'when the client attempts to update an aggregate list' do
        subject(:update_inventory_list) { put "/inventory_lists/#{inventory_list.id}", params: { inventory_list: { title: 'Foo' } }.to_json, headers: }

        let!(:inventory_list) { create(:aggregate_inventory_list, game:) }
        let(:game) { create(:game, user:) }

        it "doesn't update the list" do
          update_inventory_list
          expect(inventory_list.reload.title).to eq 'All Items'
        end

        it 'returns status 405 (method not allowed)' do
          update_inventory_list
          expect(response.status).to eq 405
        end

        it 'returns a helpful error body' do
          update_inventory_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot manually update an aggregate inventory list'] })
        end
      end

      context 'when the client attempts to change a regular list to an aggregate list' do
        subject(:update_inventory_list) { put "/inventory_lists/#{inventory_list.id}", params: { inventory_list: { aggregate: true } }.to_json, headers: }

        let!(:inventory_list) { create(:inventory_list, game:) }
        let(:game) { create(:game, user:) }

        it "doesn't update the list" do
          update_inventory_list
          expect(inventory_list.reload.aggregate).to eq false
        end

        it 'returns status 422' do
          update_inventory_list
          expect(response.status).to eq 422
        end

        it 'returns a helpful error body' do
          update_inventory_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot make a regular inventory list an aggregate list'] })
        end
      end

      context 'when something unexpected goes wrong' do
        subject(:update_inventory_list) { put "/inventory_lists/#{inventory_list.id}", params: { inventory_list: { title: 'Some New Title' } }.to_json, headers: }

        let!(:inventory_list) { create(:inventory_list, game:) }
        let(:game) { create(:game, user:) }

        before { allow_any_instance_of(User).to receive(:inventory_lists).and_raise(StandardError, 'Something went catastrophically wrong') }

        it 'returns status 500' do
          update_inventory_list
          expect(response.status).to eq 500
        end

        it 'returns the error in the body' do
          update_inventory_list
          expect(response.body).to eq({ errors: ['Something went catastrophically wrong'] }.to_json)
        end
      end
    end

    context 'when unauthenticated' do
      let!(:inventory_list) { create(:inventory_list) }
      let(:list_id) { inventory_list.id }

      before { stub_unsuccessful_login }

      it "doesn't update the inventory list" do
        expect { update_inventory_list }
          .not_to change(inventory_list.reload, :title)
      end

      it 'returns status 401' do
        update_inventory_list
        expect(response.status).to eq 401
      end

      it "doesn't return any data" do
        update_inventory_list
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'DELETE /inventory_lists/:id' do
    subject(:delete_inventory_list) { delete "/inventory_lists/#{inventory_list.id}", headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }
      let(:game) { create(:game, user:) }

      before { stub_successful_login }

      context 'when the inventory list exists' do
        let!(:inventory_list) { create(:inventory_list, game:) }

        context "when this is the game's last regular inventory list" do
          it 'deletes the inventory list and the aggregate list' do
            expect { delete_inventory_list }
              .to change(game.inventory_lists, :count).from(2).to(0)
          end

          it 'returns status 204' do
            delete_inventory_list
            expect(response.status).to eq 204
          end

          it "doesn't return any data" do
            delete_inventory_list
            expect(response.body).to be_blank
          end
        end

        context "when this is not the game's last regular inventory list" do
          before { create(:inventory_list, game:, aggregate_list: game.aggregate_inventory_list) }

          it 'deletes the requested inventory list' do
            expect { delete_inventory_list }
              .to change(game.inventory_lists, :count).from(3).to(2)
          end

          it 'returns status 200' do
            delete_inventory_list
            expect(response.status).to eq 200
          end

          it 'returns the aggregate list in the body' do
            delete_inventory_list
            expect(response.body).to eq(game.aggregate_inventory_list.to_json)
          end
        end
      end

      context 'when the inventory list does not exist' do
        let(:inventory_list) { double(id: 24_588) }

        it 'returns 404' do
          delete_inventory_list
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          delete_inventory_list
          expect(response.body).to be_blank
        end
      end

      context 'when the inventory list belongs to another user' do
        let!(:inventory_list) { create(:inventory_list) }

        it "doesn't destroy the inventory list" do
          expect { delete_inventory_list }
            .not_to change(InventoryList, :count)
        end

        it 'returns 404' do
          delete_inventory_list
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          delete_inventory_list
          expect(response.body).to be_blank
        end
      end

      context 'when attempting to delete the aggregate list' do
        let!(:inventory_list) { create(:aggregate_inventory_list, game:) }

        it "doesn't delete the list" do
          expect { delete_inventory_list }
            .not_to change(InventoryList, :count)
        end

        it 'returns status 405' do
          delete_inventory_list
          expect(response.status).to eq 405
        end

        it 'returns an "errors" array' do
          delete_inventory_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot manually delete an aggregate inventory list'] })
        end
      end
    end

    context 'when unauthenticated' do
      let!(:inventory_list) { create(:inventory_list) }

      before { stub_unsuccessful_login }

      it "doesn't destroy the inventory list" do
        expect { delete_inventory_list }
          .not_to change(InventoryList, :count)
      end

      it 'returns status 401' do
        delete_inventory_list
        expect(response.status).to eq 401
      end

      it "doesn't return any data" do
        delete_inventory_list
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end
end

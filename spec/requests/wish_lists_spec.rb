# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'WishLists', type: :request do
  let(:headers) do
    {
      'Content-Type' => 'application/json',
      'Authorization' => 'Bearer xxxxxxx',
    }
  end

  describe 'POST games/:game_id/wish_lists' do
    subject(:create_wish_list) { post "/games/#{game.id}/wish_lists", params: { wish_list: {} }.to_json, headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when all goes well' do
        let(:game) { create(:game, user:) }

        context 'when an aggregate list has also been created' do
          it 'creates a new wish list' do
            expect { create_wish_list }
              .to change(game.wish_lists, :count).from(0).to(2) # because of the aggregate list
          end

          it 'returns both wish lists' do
            create_wish_list
            expect(response.body).to eq(game.wish_lists.index_order.to_json)
          end

          it 'returns status 201' do
            create_wish_list
            expect(response.status).to eq 201
          end
        end

        context 'when only the new wish list has been created' do
          before do
            create(:wish_list, game:)
          end

          it 'creates one list' do
            expect { create_wish_list }
              .to change(game.wish_lists, :count).from(2).to(3)
          end

          it 'returns only the created list' do
            create_wish_list
            expect(response.body).to eq([game.wish_lists.unscoped.last].to_json)
          end

          it 'returns status 201' do
            create_wish_list
            expect(response.status).to eq 201
          end
        end

        context 'when the request does not include a body' do
          subject(:create_wish_list) { post "/games/#{game.id}/wish_lists", headers: }

          before do
            # let's not have this request create an aggregate list too
            create(:aggregate_wish_list, game:)
          end

          it 'returns status 201' do
            create_wish_list
            expect(response.status).to eq 201
          end

          it 'creates the wish list with a default title' do
            create_wish_list
            expect(game.wish_lists.last.title).to eq 'My List 1'
          end
        end
      end

      context 'when the game is not found' do
        let(:game) { double(id: 84_968_294) }

        it 'returns status 404' do
          create_wish_list
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          create_wish_list
          expect(response.body).to be_empty
        end
      end

      context 'when the game belongs to another user' do
        let(:game) { create(:game) }

        it "doesn't create a wish list" do
          expect { create_wish_list }
            .not_to change(WishList, :count)
        end

        it 'returns status 404' do
          create_wish_list
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          create_wish_list
          expect(response.body).to be_empty
        end
      end

      context 'when the params are invalid' do
        subject(:create_wish_list) do
          post "/games/#{game.id}/wish_lists",
               params: {
                 wish_list: { title: existing_list.title },
               }.to_json,
               headers:
        end

        let(:game) { create(:game, user:) }
        let(:existing_list) { create(:wish_list, game:) }

        it 'returns status 422' do
          create_wish_list
          expect(response.status).to eq 422
        end

        it 'returns the errors' do
          create_wish_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Title must be unique per game'] })
        end
      end

      context 'when the client attempts to create an aggregate list' do
        subject(:create_wish_list) do
          post "/games/#{game.id}/wish_lists",
               params: {
                 wish_list: { aggregate: true },
               }.to_json,
               headers:
        end

        let(:game) { create(:game, user:) }

        it "doesn't create a list" do
          expect { create_wish_list }
            .not_to change(game.wish_lists, :count)
        end

        it 'returns an error' do
          create_wish_list
          expect(response.status).to eq 422
        end

        it 'returns a helpful error body' do
          create_wish_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot manually create an aggregate wish list'] })
        end
      end
    end

    context 'when unauthenticated' do
      let!(:game) { create(:game) }

      before do
        stub_unsuccessful_login
      end

      it "doesn't create a wish list" do
        expect { create_wish_list }
          .not_to change(WishList, :count)
      end

      it 'returns status 401' do
        create_wish_list
        expect(response.status).to eq 401
      end

      it "doesn't return any data" do
        create_wish_list
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'PUT /wish_lists/:id' do
    subject(:update_wish_list) { put "/wish_lists/#{list_id}", params:, headers: }

    let(:params) { { wish_list: { title: 'Severin Manor' } }.to_json }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when all goes well' do
        let!(:wish_list) { create(:wish_list, game:) }
        let(:game) { create(:game, user:) }
        let(:list_id) { wish_list.id }

        context 'when the request body sets a valid title' do
          it 'updates the title' do
            update_wish_list
            expect(wish_list.reload.title).to eq 'Severin Manor'
          end

          it 'returns the updated list' do
            update_wish_list
            # This ugly hack is needed because if we don't parse the JSON, it'll make an error
            # if everything isn't in the exact same order, but if we just use wish_list.attributes
            # it won't include the list_items. Ugly.
            expect(JSON.parse(response.body)).to eq(JSON.parse(wish_list.reload.to_json))
          end

          it 'returns status 200' do
            update_wish_list
            expect(response.status).to eq 200
          end
        end

        context 'when the params include a null title' do
          let(:params) { { wish_list: { title: nil } }.to_json }

          it 'sets a default title' do
            update_wish_list
            expect(wish_list.reload.title).to eq 'My List 1'
          end

          it 'returns the updated list' do
            update_wish_list
            # This ugly hack is needed because if we don't parse the JSON, it'll make an error
            # if everything isn't in the exact same order, but if we just use wish_list.attributes
            # it won't include the list_items. Ugly.
            expect(JSON.parse(response.body)).to eq(JSON.parse(wish_list.reload.to_json))
          end

          it 'returns status 200' do
            update_wish_list
            expect(response.status).to eq 200
          end
        end

        context 'when the "wish_list" param is empty"' do
          let(:params) { { wish_list: {} }.to_json }

          it "doesn't change the attributes" do
            expect { update_wish_list }
              .not_to change(wish_list.reload, :attributes)
          end

          it 'returns the updated list' do
            update_wish_list
            # This ugly hack is needed because if we don't parse the JSON, it'll make an error
            # if everything isn't in the exact same order, but if we just use wish_list.attributes
            # it won't include the list_items. Ugly.
            expect(JSON.parse(response.body)).to eq(JSON.parse(wish_list.reload.to_json))
          end

          it 'returns status 200' do
            update_wish_list
            expect(response.status).to eq 200
          end
        end

        context 'when there is no request body"' do
          let(:params) { nil }

          it "doesn't change the attributes" do
            expect { update_wish_list }
              .not_to change(wish_list.reload, :attributes)
          end

          it 'returns the updated list' do
            update_wish_list
            # This ugly hack is needed because if we don't parse the JSON, it'll make an error
            # if everything isn't in the exact same order, but if we just use wish_list.attributes
            # it won't include the list_items. Ugly.
            expect(JSON.parse(response.body)).to eq(JSON.parse(wish_list.reload.to_json))
          end

          it 'returns status 200' do
            update_wish_list
            expect(response.status).to eq 200
          end
        end
      end

      context 'when the params are invalid' do
        subject(:update_wish_list) do
          put "/wish_lists/#{list_id}",
              params: {
                wish_list: { title: other_list.title },
              }.to_json,
              headers:
        end

        let!(:wish_list) { create(:wish_list, game:) }
        let(:game) { create(:game, user:) }
        let(:list_id) { wish_list.id }
        let(:other_list) { create(:wish_list, game:) }

        it 'returns status 422' do
          update_wish_list
          expect(response.status).to eq 422
        end

        it 'returns the errors' do
          update_wish_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Title must be unique per game'] })
        end
      end

      context 'when the list does not exist' do
        let(:list_id) { 245_285 }

        it 'returns status 404' do
          update_wish_list
          expect(response.status).to eq 404
        end

        it "doesn't return data" do
          update_wish_list
          expect(response.body).to be_blank
        end
      end

      context 'when the list belongs to another user' do
        let!(:wish_list) { create(:wish_list) }
        let(:list_id) { wish_list.id }

        it "doesn't update the wish list" do
          expect { update_wish_list }
            .not_to change(wish_list.reload, :title)
        end

        it 'returns status 404' do
          update_wish_list
          expect(response.status).to eq 404
        end

        it "doesn't return data" do
          update_wish_list
          expect(response.body).to be_blank
        end
      end

      context 'when the client attempts to update an aggregate list' do
        subject(:update_wish_list) do
          put "/wish_lists/#{wish_list.id}",
              params: {
                wish_list: { title: 'Foo' },
              }.to_json,
              headers:
        end

        let!(:wish_list) { create(:aggregate_wish_list, game:) }
        let(:game) { create(:game, user:) }

        it "doesn't update the list" do
          update_wish_list
          expect(wish_list.reload.title).to eq 'All Items'
        end

        it 'returns status 405 (method not allowed)' do
          update_wish_list
          expect(response.status).to eq 405
        end

        it 'returns a helpful error body' do
          update_wish_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot manually update an aggregate wish list'] })
        end
      end

      context 'when the client attempts to change a regular list to an aggregate list' do
        subject(:update_wish_list) do
          put "/wish_lists/#{wish_list.id}",
              params: {
                wish_list: { aggregate: true },
              }.to_json,
              headers:
        end

        let!(:wish_list) { create(:wish_list, game:) }
        let(:game) { create(:game, user:) }

        it "doesn't update the list" do
          update_wish_list
          expect(wish_list.reload.aggregate).to eq false
        end

        it 'returns status 422' do
          update_wish_list
          expect(response.status).to eq 422
        end

        it 'returns a helpful error body' do
          update_wish_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot make a regular wish list an aggregate list'] })
        end
      end

      context 'when something unexpected goes wrong' do
        subject(:update_wish_list) do
          put "/wish_lists/#{wish_list.id}",
              params: {
                wish_list: { title: 'Some New Title' },
              }.to_json,
              headers:
        end

        let!(:wish_list) { create(:wish_list, game:) }
        let(:game) { create(:game, user:) }

        before do
          allow_any_instance_of(User)
            .to receive(:wish_lists)
                  .and_raise(StandardError, 'Something went catastrophically wrong')
        end

        it 'returns status 500' do
          update_wish_list
          expect(response.status).to eq 500
        end

        it 'returns the error in the body' do
          update_wish_list
          expect(response.body).to eq({ errors: ['Something went catastrophically wrong'] }.to_json)
        end
      end
    end

    context 'when unauthenticated' do
      let!(:wish_list) { create(:wish_list) }
      let(:list_id) { wish_list.id }

      before do
        stub_unsuccessful_login
      end

      it "doesn't update the wish list" do
        expect { update_wish_list }
          .not_to change(wish_list.reload, :title)
      end

      it 'returns status 401' do
        update_wish_list
        expect(response.status).to eq 401
      end

      it "doesn't return any data" do
        update_wish_list
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'PATCH /wish_lists/:id' do
    subject(:update_wish_list) { patch "/wish_lists/#{list_id}", params:, headers: }

    let(:params) { { wish_list: { title: 'Severin Manor' } }.to_json }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when all goes well' do
        let!(:wish_list) { create(:wish_list, game:) }
        let(:game) { create(:game, user:) }
        let(:list_id) { wish_list.id }

        context 'when the request body sets a valid title' do
          it 'updates the title' do
            update_wish_list
            expect(wish_list.reload.title).to eq 'Severin Manor'
          end

          it 'returns the updated list' do
            update_wish_list
            # This ugly hack is needed because if we don't parse the JSON, it'll make an error
            # if everything isn't in the exact same order, but if we just use wish_list.attributes
            # it won't include the list_items. Ugly.
            expect(JSON.parse(response.body)).to eq(JSON.parse(wish_list.reload.to_json))
          end

          it 'returns status 200' do
            update_wish_list
            expect(response.status).to eq 200
          end
        end

        context 'when the params include a null title' do
          let(:params) { { wish_list: { title: nil } }.to_json }

          it 'sets a default title' do
            update_wish_list
            expect(wish_list.reload.title).to eq 'My List 1'
          end

          it 'returns the updated list' do
            update_wish_list
            # This ugly hack is needed because if we don't parse the JSON, it'll make an error
            # if everything isn't in the exact same order, but if we just use wish_list.attributes
            # it won't include the list_items. Ugly.
            expect(JSON.parse(response.body)).to eq(JSON.parse(wish_list.reload.to_json))
          end

          it 'returns status 200' do
            update_wish_list
            expect(response.status).to eq 200
          end
        end

        context 'when the "wish_list" param is empty"' do
          let(:params) { { wish_list: {} }.to_json }

          it "doesn't change the attributes" do
            expect { update_wish_list }
              .not_to change(wish_list.reload, :attributes)
          end

          it 'returns the updated list' do
            update_wish_list
            # This ugly hack is needed because if we don't parse the JSON, it'll make an error
            # if everything isn't in the exact same order, but if we just use wish_list.attributes
            # it won't include the list_items. Ugly.
            expect(JSON.parse(response.body)).to eq(JSON.parse(wish_list.reload.to_json))
          end

          it 'returns status 200' do
            update_wish_list
            expect(response.status).to eq 200
          end
        end

        context 'when there is no request body"' do
          let(:params) { nil }

          it "doesn't change the attributes" do
            expect { update_wish_list }
              .not_to change(wish_list.reload, :attributes)
          end

          it 'returns the updated list' do
            update_wish_list
            # This ugly hack is needed because if we don't parse the JSON, it'll make an error
            # if everything isn't in the exact same order, but if we just use wish_list.attributes
            # it won't include the list_items. Ugly.
            expect(JSON.parse(response.body)).to eq(JSON.parse(wish_list.reload.to_json))
          end

          it 'returns status 200' do
            update_wish_list
            expect(response.status).to eq 200
          end
        end
      end

      context 'when the params are invalid' do
        subject(:update_wish_list) do
          patch "/wish_lists/#{list_id}",
                params: {
                  wish_list: { title: other_list.title },
                }.to_json,
                headers:
        end

        let!(:wish_list) { create(:wish_list, game:) }
        let(:game) { create(:game, user:) }
        let(:list_id) { wish_list.id }
        let(:other_list) { create(:wish_list, game:) }

        it 'returns status 422' do
          update_wish_list
          expect(response.status).to eq 422
        end

        it 'returns the errors' do
          update_wish_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Title must be unique per game'] })
        end
      end

      context 'when the list does not exist' do
        let(:list_id) { 245_285 }

        it 'returns status 404' do
          update_wish_list
          expect(response.status).to eq 404
        end

        it "doesn't return data" do
          update_wish_list
          expect(response.body).to be_blank
        end
      end

      context 'when the list belongs to another user' do
        let!(:wish_list) { create(:wish_list) }
        let(:list_id) { wish_list.id }

        it "doesn't update the wish list" do
          expect { update_wish_list }
            .not_to change(wish_list.reload, :title)
        end

        it 'returns status 404' do
          update_wish_list
          expect(response.status).to eq 404
        end

        it "doesn't return data" do
          update_wish_list
          expect(response.body).to be_blank
        end
      end

      context 'when the client attempts to update an aggregate list' do
        subject(:update_wish_list) do
          patch "/wish_lists/#{wish_list.id}",
                params: { wish_list: { title: 'Foo' } }.to_json,
                headers:
        end

        let!(:wish_list) { create(:aggregate_wish_list, game:) }
        let(:game) { create(:game, user:) }

        it "doesn't update the list" do
          update_wish_list
          expect(wish_list.reload.title).to eq 'All Items'
        end

        it 'returns status 405 (method not allowed)' do
          update_wish_list
          expect(response.status).to eq 405
        end

        it 'returns a helpful error body' do
          update_wish_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot manually update an aggregate wish list'] })
        end
      end

      context 'when the client attempts to change a regular list to an aggregate list' do
        subject(:update_wish_list) do
          patch "/wish_lists/#{wish_list.id}",
                params: { wish_list: { aggregate: true } }.to_json,
                headers:
        end

        let!(:wish_list) { create(:wish_list, game:) }
        let(:game) { create(:game, user:) }

        it "doesn't update the list" do
          update_wish_list
          expect(wish_list.reload.aggregate).to eq false
        end

        it 'returns status 422' do
          update_wish_list
          expect(response.status).to eq 422
        end

        it 'returns a helpful error body' do
          update_wish_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot make a regular wish list an aggregate list'] })
        end
      end

      context 'when something unexpected goes wrong' do
        subject(:update_wish_list) do
          patch "/wish_lists/#{wish_list.id}",
                params: { wish_list: { title: 'Some New Title' } }.to_json,
                headers:
        end

        let!(:wish_list) { create(:wish_list, game:) }
        let(:game) { create(:game, user:) }

        before do
          allow_any_instance_of(User)
            .to receive(:wish_lists)
                  .and_raise(StandardError, 'Something went catastrophically wrong')
        end

        it 'returns status 500' do
          update_wish_list
          expect(response.status).to eq 500
        end

        it 'returns the error in the body' do
          update_wish_list
          expect(response.body).to eq({ errors: ['Something went catastrophically wrong'] }.to_json)
        end
      end
    end

    context 'when unauthenticated' do
      let!(:wish_list) { create(:wish_list) }
      let(:list_id) { wish_list.id }

      before do
        stub_unsuccessful_login
      end

      it "doesn't update the wish list" do
        expect { update_wish_list }
          .not_to change(wish_list.reload, :title)
      end

      it 'returns status 401' do
        update_wish_list
        expect(response.status).to eq 401
      end

      it "doesn't return any data" do
        update_wish_list
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'GET games/:game_id/wish_lists' do
    subject(:get_index) { get "/games/#{game.id}/wish_lists", headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

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

      context 'when there are no wish lists for that game' do
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

      context 'when there are wish lists for that game' do
        let(:game) { create(:game_with_wish_lists, user:) }

        it 'returns status 200' do
          get_index
          expect(response.status).to eq 200
        end

        it 'returns the wish lists in index order' do
          get_index
          expect(response.body).to eq game.wish_lists.index_order.to_json
        end
      end
    end

    context 'when unauthenticated' do
      let!(:game) { create(:game) }

      before do
        stub_unsuccessful_login
      end

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

  describe 'DELETE /wish_lists/:id' do
    subject(:delete_wish_list) { delete "/wish_lists/#{wish_list.id}", headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }
      let(:game) { create(:game, user:) }

      before do
        stub_successful_login
      end

      context 'when the wish list exists' do
        let!(:wish_list) { create(:wish_list, game:) }
        let!(:wish_list_id) { wish_list.id }

        context "when this is the game's last regular wish list" do
          let!(:aggregate_list_id) { game.aggregate_wish_list.id }

          let(:expected_response_body) do
            {
              deleted: [aggregate_list_id, wish_list_id],
            }.to_json
          end

          it 'deletes the wish list and the aggregate list' do
            expect { delete_wish_list }
              .to change(game.wish_lists, :count).from(2).to(0)
          end

          it 'returns status 200' do
            delete_wish_list
            expect(response.status).to eq 200
          end

          it 'returns the IDs of the deleted lists' do
            delete_wish_list
            expect(response.body).to eq expected_response_body
          end
        end

        context "when this is not the game's last regular wish list" do
          let(:expected_response_body) do
            {
              deleted: [wish_list_id],
              aggregate: game.aggregate_wish_list,
            }.to_json
          end

          before do
            create(:wish_list, game:)
          end

          it 'deletes the requested wish list' do
            expect { delete_wish_list }
              .to change(game.wish_lists, :count).from(3).to(2)
          end

          it 'returns status 200' do
            delete_wish_list
            expect(response.status).to eq 200
          end

          it 'returns the deleted list ID and the aggregate list' do
            delete_wish_list
            expect(response.body).to eq(expected_response_body)
          end
        end
      end

      context 'when the wish list does not exist' do
        let(:wish_list) { double(id: 24_588) }

        it 'returns 404' do
          delete_wish_list
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          delete_wish_list
          expect(response.body).to be_blank
        end
      end

      context 'when the wish list belongs to another user' do
        let!(:wish_list) { create(:wish_list) }

        it "doesn't destroy the wish list" do
          expect { delete_wish_list }
            .not_to change(WishList, :count)
        end

        it 'returns 404' do
          delete_wish_list
          expect(response.status).to eq 404
        end

        it "doesn't return any data" do
          delete_wish_list
          expect(response.body).to be_blank
        end
      end

      context 'when attempting to delete the aggregate list' do
        let!(:wish_list) { create(:aggregate_wish_list, game:) }

        it "doesn't delete the list" do
          expect { delete_wish_list }
            .not_to change(WishList, :count)
        end

        it 'returns status 405' do
          delete_wish_list
          expect(response.status).to eq 405
        end

        it 'returns an "errors" array' do
          delete_wish_list
          expect(JSON.parse(response.body)).to eq({ 'errors' => ['Cannot manually delete an aggregate wish list'] })
        end
      end
    end

    context 'when unauthenticated' do
      let!(:wish_list) { create(:wish_list) }

      before do
        stub_unsuccessful_login
      end

      it "doesn't destroy the wish list" do
        expect { delete_wish_list }
          .not_to change(WishList, :count)
      end

      it 'returns status 401' do
        delete_wish_list
        expect(response.status).to eq 401
      end

      it "doesn't return any data" do
        delete_wish_list
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Games', type: :request do
  let(:headers) do
    {
      'Content-Type' => 'application/json',
      'Authorization' => 'Bearer xxxxxxx',
    }
  end

  describe 'GET /games' do
    subject(:get_games) { get '/games', headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when the user has no games' do
        it 'returns status 200' do
          get_games
          expect(response.status).to eq(200)
        end

        it 'returns an empty array' do
          get_games
          expect(response.body).to eq('[]')
        end
      end

      context 'when the user has games' do
        before do
          create_list(:game, 2, user:)
          create(:game) # for another user, shouldn't be returned
        end

        it 'returns status 200' do
          get_games
          expect(response.status).to eq(200)
        end

        it "returns the authenticated user's games" do
          get_games
          expect(response.body).to eq(user.games.index_order.to_json)
        end
      end

      context 'when something unexpected goes wrong' do
        before do
          allow_any_instance_of(User).to receive(:games).and_raise(StandardError, 'Something went horribly wrong')
        end

        it 'returns status 500' do
          get_games
          expect(response.status).to eq(500)
        end

        it 'returns the error message' do
          get_games
          expect(response.body).to eq({ errors: ['Something went horribly wrong'] }.to_json)
        end
      end
    end

    context 'when not authenticated' do
      before do
        create(:authenticated_user)
        stub_unsuccessful_login
      end

      it 'returns status 401' do
        get_games
        expect(response.status).to eq(401)
      end

      it "doesn't return any data" do
        get_games
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'POST /games' do
    subject(:create_game) { post '/games', headers:, params: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when all goes well' do
        let(:params) { { game: { name: 'My Game' } }.to_json }

        it 'creates a game' do
          expect { create_game }
            .to change(user.games, :count).by(1)
        end

        it 'returns status 201' do
          create_game
          expect(response.status).to eq(201)
        end

        it 'returns the game' do
          create_game
          expect(response.body).to eq(user.games.last.to_json)
        end
      end

      context 'when the params are invalid' do
        let(:params) { { game: { name: '@#*!)&' } }.to_json }

        it "doesn't create a game" do
          expect { create_game }
            .not_to change(user.games, :count)
        end

        it 'returns status 422' do
          create_game
          expect(response.status).to eq(422)
        end

        it 'returns the errors in the response body' do
          create_game
          expect(response.body).to eq({ errors: ["Name can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')"] }.to_json)
        end
      end

      context 'when something unexpected goes wrong' do
        let(:params) { { name: 'My Game' }.to_json }

        before do
          allow_any_instance_of(Game).to receive(:save).and_raise(StandardError, 'Something has gone horribly wrong')
        end

        it 'returns a 500 status' do
          create_game
          expect(response.status).to eq(500)
        end

        it 'returns the error message' do
          create_game
          expect(response.body).to eq({ errors: ['Something has gone horribly wrong'] }.to_json)
        end
      end
    end

    context 'when not authenticated' do
      let!(:user) { create(:authenticated_user) }
      let!(:game) { create(:game, user:) }
      let(:params) { { game: { name: 'Skyrim Game 1' } } }

      before do
        stub_unsuccessful_login
      end

      it "doesn't create a game" do
        expect { create_game }
          .not_to change(Game, :count)
      end

      it 'returns status 401' do
        create_game
        expect(response.status).to eq(401)
      end

      it "doesn't return any data" do
        create_game
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'PATCH /games/:id' do
    subject(:update_game) { patch "/games/#{game.id}", headers:, params: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when all goes well' do
        let(:game) { create(:game, user:) }
        let(:params) { { game: { name: 'New Name' } }.to_json }

        it 'updates the game' do
          update_game
          expect(game.reload.name).to eq('New Name')
        end

        it 'returns status 200' do
          update_game
          expect(response.status).to eq(200)
        end

        it 'returns the game in the response body' do
          update_game

          # There is a weird issue with serialisation in some of the tests where the timestamps
          # on the deserialised response body differs from those on the model by '+0000' This is
          # the only way I've found to fix the tests.
          game_attributes_without_timestamps = game.reload.attributes.except('created_at', 'updated_at')
          response_body_without_timestamps = JSON.parse(response.body).except('created_at', 'updated_at')

          expect(response_body_without_timestamps).to eq(game_attributes_without_timestamps)
        end
      end

      context 'when the params are invalid' do
        let!(:game) { create(:game, user:) }
        let!(:other_game) { create(:game, user:) }
        let(:params) { { game: { name: other_game.name } }.to_json }

        it 'returns status 422' do
          update_game
          expect(response.status).to eq(422)
        end

        it 'returns the errors' do
          update_game
          expect(response.body).to eq({ errors: ['Name must be unique'] }.to_json)
        end
      end

      context 'when the game does not exist' do
        let(:game) { double(id: 829_315) }
        let(:params) { { game: { name: 'New Name' } }.to_json }

        it 'returns status 404' do
          update_game
          expect(response.status).to eq(404)
        end

        it "doesn't return any data" do
          update_game
          expect(response.body).to be_blank
        end
      end

      context 'when the game belongs to another user' do
        let!(:game) { create(:game) }
        let(:params) { { game: { name: 'New Name' } }.to_json }

        it "doesn't update the game" do
          expect { update_game }
            .not_to change(game.reload, :name)
        end

        it 'returns status 404' do
          update_game
          expect(response.status).to eq(404)
        end
      end

      context 'when something unexpected goes wrong' do
        let(:game) { create(:game, user:) }
        let(:params) { { game: { description: 'New description' } }.to_json }

        before do
          allow_any_instance_of(Game).to receive(:update).and_raise(StandardError, 'Something went horribly wrong')
        end

        it 'returns a 500 status' do
          update_game
          expect(response.status).to eq(500)
        end

        it 'returns the error message' do
          update_game
          expect(response.body).to eq({ errors: ['Something went horribly wrong'] }.to_json)
        end
      end
    end

    context 'when not authenticated' do
      let!(:user) { create(:authenticated_user) }
      let!(:game) { create(:game, user:) }
      let(:params) { { game: { name: 'Changed Name' } } }

      before do
        stub_unsuccessful_login
      end

      it "doesn't update the game" do
        update_game
        expect(game.reload.name).not_to eq('Changed Name')
      end

      it 'returns status 401' do
        update_game
        expect(response.status).to eq(401)
      end

      it "doesn't return any data" do
        update_game
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'PUT /games/:id' do
    subject(:update_game) { put "/games/#{game.id}", headers:, params: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when all goes well' do
        let(:game) { create(:game, user:) }
        let(:params) { { game: { name: 'New Name' } }.to_json }

        it 'updates the game' do
          update_game
          expect(game.reload.name).to eq('New Name')
        end

        it 'returns status 200' do
          update_game
          expect(response.status).to eq(200)
        end

        it 'returns the game in the response body' do
          update_game

          # There is a weird issue with serialisation in some of the tests where the timestamps
          # on the deserialised response body differs from those on the model by '+0000' This is
          # the only way I've found to fix the tests.
          game_attributes_without_timestamps = game.reload.attributes.except('created_at', 'updated_at')
          response_body_without_timestamps = JSON.parse(response.body).except('created_at', 'updated_at')

          expect(response_body_without_timestamps).to eq(game_attributes_without_timestamps)
        end
      end

      context 'when the params are invalid' do
        let!(:game) { create(:game, user:) }
        let!(:other_game) { create(:game, user:) }
        let(:params) { { game: { name: other_game.name } }.to_json }

        it 'returns status 422' do
          update_game
          expect(response.status).to eq(422)
        end

        it 'returns the errors' do
          update_game
          expect(response.body).to eq({ errors: ['Name must be unique'] }.to_json)
        end
      end

      context 'when the game does not exist' do
        let(:game) { double(id: 829_315) }
        let(:params) { { game: { name: 'New Name' } }.to_json }

        it 'returns status 404' do
          update_game
          expect(response.status).to eq(404)
        end

        it "doesn't return any data" do
          update_game
          expect(response.body).to be_blank
        end
      end

      context 'when the game belongs to another user' do
        let!(:game) { create(:game) }
        let(:params) { { game: { name: 'New Name' } }.to_json }

        it "doesn't update the game" do
          expect { update_game }
            .not_to change(game.reload, :name)
        end

        it 'returns status 404' do
          update_game
          expect(response.status).to eq(404)
        end
      end

      context 'when something unexpected goes wrong' do
        let(:game) { create(:game, user:) }
        let(:params) { { game: { description: 'New description' } }.to_json }

        before do
          allow_any_instance_of(Game).to receive(:update).and_raise(StandardError, 'Something went horribly wrong')
        end

        it 'returns a 500 status' do
          update_game
          expect(response.status).to eq(500)
        end

        it 'returns the error message' do
          update_game
          expect(response.body).to eq({ errors: ['Something went horribly wrong'] }.to_json)
        end
      end
    end

    context 'when not authenticated' do
      let!(:game) { create(:game, user:) }
      let(:user) { create(:authenticated_user) }
      let(:params) { { game: { name: 'Changed Name' } } }

      before do
        stub_unsuccessful_login
      end

      it "doesn't update the game" do
        update_game
        expect(game.reload.name).not_to eq('Changed Name')
      end

      it 'returns status 401' do
        update_game
        expect(response.status).to eq(401)
      end

      it "doesn't return any data" do
        update_game
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'DELETE /games/:id' do
    subject(:destroy_game) { delete "/games/#{game.id}", headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when all goes well' do
        let!(:game) { create(:game, user:) }

        it 'destroys the game' do
          expect { destroy_game }
            .to change(user.games, :count).from(1).to(0)
        end

        it 'returns status 204' do
          destroy_game
          expect(response.status).to eq(204)
        end

        it "doesn't return any data" do
          destroy_game
          expect(response.body).to be_blank
        end
      end

      context 'when the game does not exist' do
        let(:game) { double(id: 752_809) }

        it 'returns status 404' do
          destroy_game
          expect(response.status).to eq(404)
        end

        it "doesn't return any data" do
          destroy_game
          expect(response.body).to be_blank
        end
      end

      context 'when the game belongs to another user' do
        let!(:game) { create(:game) }

        it "doesn't destroy the game" do
          expect { destroy_game }
            .not_to change(Game, :count)
        end

        it 'returns status 404' do
          destroy_game
          expect(response.status).to eq(404)
        end
      end

      context 'when something unexpected goes wrong' do
        let!(:game) { create(:game, user:) }

        before do
          allow_any_instance_of(Game).to receive(:destroy!).and_raise(StandardError, 'Something went horribly wrong')
        end

        it 'returns status 500' do
          destroy_game
          expect(response.status).to eq(500)
        end

        it 'returns the error in the body' do
          destroy_game
          expect(response.body).to eq({ errors: ['Something went horribly wrong'] }.to_json)
        end
      end
    end

    context 'when not authenticated' do
      let!(:user) { create(:authenticated_user) }
      let!(:game) { create(:game, user:) }

      before do
        stub_unsuccessful_login
      end

      it "doesn't destroy the game" do
        expect { destroy_game }
          .not_to change(Game, :count)
      end

      it 'returns status 401' do
        destroy_game
        expect(response.status).to eq(401)
      end

      it "doesn't return any data" do
        destroy_game
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end
end

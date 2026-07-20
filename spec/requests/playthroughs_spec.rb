# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Playthroughs', type: :request do
  let(:headers) do
    {
      'Content-Type' => 'application/json',
      'Authorization' => 'Bearer xxxxxxx',
    }
  end

  describe 'GET /playthroughs' do
    subject(:get_playthroughs) { get '/playthroughs', headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when the user has no playthroughs' do
        it 'returns status 200' do
          get_playthroughs
          expect(response.status).to eq(200)
        end

        it 'returns an empty array' do
          get_playthroughs
          expect(response.body).to eq('[]')
        end
      end

      context 'when the user has playthroughs' do
        before do
          create_list(:playthrough, 2, user:)
          create(:playthrough) # for another user, shouldn't be returned
        end

        it 'returns status 200' do
          get_playthroughs
          expect(response.status).to eq(200)
        end

        it "returns the authenticated user's playthroughs" do
          get_playthroughs
          expect(response.body).to eq(user.playthroughs.index_order.to_json)
        end
      end

      context 'when something unexpected goes wrong' do
        before do
          allow_any_instance_of(User).to receive(:playthroughs).and_raise(StandardError, 'Something went horribly wrong')
        end

        it 'returns status 500' do
          get_playthroughs
          expect(response.status).to eq(500)
        end

        it 'returns the error message' do
          get_playthroughs
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
        get_playthroughs
        expect(response.status).to eq(401)
      end

      it "doesn't return any data" do
        get_playthroughs
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'POST /playthroughs' do
    subject(:create_playthrough) { post '/playthroughs', headers:, params: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when all goes well' do
        let(:params) { { playthrough: { name: 'My playthrough' } }.to_json }

        it 'creates a playthrough' do
          expect { create_playthrough }
            .to change(user.playthroughs, :count).by(1)
        end

        it 'returns status 201' do
          create_playthrough
          expect(response.status).to eq(201)
        end

        it 'returns the playthrough' do
          create_playthrough
          expect(response.body).to eq(user.playthroughs.last.to_json)
        end
      end

      context 'when the params are invalid' do
        let(:params) { { playthrough: { name: '@#*!)&' } }.to_json }

        it "doesn't create a playthrough" do
          expect { create_playthrough }
            .not_to change(user.playthroughs, :count)
        end

        it 'returns status 422' do
          create_playthrough
          expect(response.status).to eq(422)
        end

        it 'returns the errors in the response body' do
          create_playthrough
          expect(response.body).to eq({ errors: ["Name can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')"] }.to_json)
        end
      end

      context 'when something unexpected goes wrong' do
        let(:params) { { name: 'My playthrough' }.to_json }

        before do
          allow_any_instance_of(Playthrough).to receive(:save).and_raise(StandardError, 'Something has gone horribly wrong')
        end

        it 'returns a 500 status' do
          create_playthrough
          expect(response.status).to eq(500)
        end

        it 'returns the error message' do
          create_playthrough
          expect(response.body).to eq({ errors: ['Something has gone horribly wrong'] }.to_json)
        end
      end
    end

    context 'when not authenticated' do
      let!(:user) { create(:authenticated_user) }
      let!(:playthrough) { create(:playthrough, user:) }
      let(:params) { { playthrough: { name: 'Skyrim playthrough 1' } } }

      before do
        stub_unsuccessful_login
      end

      it "doesn't create a playthrough" do
        expect { create_playthrough }
          .not_to change(Playthrough, :count)
      end

      it 'returns status 401' do
        create_playthrough
        expect(response.status).to eq(401)
      end

      it "doesn't return any data" do
        create_playthrough
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'PATCH /playthroughs/:id' do
    subject(:update_playthrough) { patch "/playthroughs/#{playthrough.id}", headers:, params: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when all goes well' do
        let(:playthrough) { create(:playthrough, user:) }
        let(:params) { { playthrough: { name: 'New Name' } }.to_json }

        it 'updates the playthrough' do
          update_playthrough
          expect(playthrough.reload.name).to eq('New Name')
        end

        it 'returns status 200' do
          update_playthrough
          expect(response.status).to eq(200)
        end

        it 'returns the playthrough in the response body' do
          update_playthrough

          # There is a weird issue with serialisation in some of the tests where the timestamps
          # on the deserialised response body differs from those on the model by '+0000' This is
          # the only way I've found to fix the tests.
          playthrough_attributes_without_timestamps = playthrough.reload.attributes.except('created_at', 'updated_at')
          response_body_without_timestamps = JSON.parse(response.body).except('created_at', 'updated_at')

          expect(response_body_without_timestamps).to eq(playthrough_attributes_without_timestamps)
        end
      end

      context 'when the params are invalid' do
        let!(:playthrough) { create(:playthrough, user:) }
        let!(:other_playthrough) { create(:playthrough, user:) }
        let(:params) { { playthrough: { name: other_playthrough.name } }.to_json }

        it 'returns status 422' do
          update_playthrough
          expect(response.status).to eq(422)
        end

        it 'returns the errors' do
          update_playthrough
          expect(response.body).to eq({ errors: ['Name must be unique'] }.to_json)
        end
      end

      context 'when the playthrough does not exist' do
        let(:playthrough) { double(id: 829_315) }
        let(:params) { { playthrough: { name: 'New Name' } }.to_json }

        it 'returns status 404' do
          update_playthrough
          expect(response.status).to eq(404)
        end

        it "doesn't return any data" do
          update_playthrough
          expect(response.body).to be_blank
        end
      end

      context 'when the playthrough belongs to another user' do
        let!(:playthrough) { create(:playthrough) }
        let(:params) { { playthrough: { name: 'New Name' } }.to_json }

        it "doesn't update the playthrough" do
          expect { update_playthrough }
            .not_to change(playthrough.reload, :name)
        end

        it 'returns status 404' do
          update_playthrough
          expect(response.status).to eq(404)
        end
      end

      context 'when something unexpected goes wrong' do
        let(:playthrough) { create(:playthrough, user:) }
        let(:params) { { playthrough: { description: 'New description' } }.to_json }

        before do
          allow_any_instance_of(Playthrough).to receive(:update).and_raise(StandardError, 'Something went horribly wrong')
        end

        it 'returns a 500 status' do
          update_playthrough
          expect(response.status).to eq(500)
        end

        it 'returns the error message' do
          update_playthrough
          expect(response.body).to eq({ errors: ['Something went horribly wrong'] }.to_json)
        end
      end
    end

    context 'when not authenticated' do
      let!(:user) { create(:authenticated_user) }
      let!(:playthrough) { create(:playthrough, user:) }
      let(:params) { { playthrough: { name: 'Changed Name' } } }

      before do
        stub_unsuccessful_login
      end

      it "doesn't update the playthrough" do
        update_playthrough
        expect(playthrough.reload.name).not_to eq('Changed Name')
      end

      it 'returns status 401' do
        update_playthrough
        expect(response.status).to eq(401)
      end

      it "doesn't return any data" do
        update_playthrough
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'PUT /playthroughs/:id' do
    subject(:update_playthrough) { put "/playthroughs/#{playthrough.id}", headers:, params: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when all goes well' do
        let(:playthrough) { create(:playthrough, user:) }
        let(:params) { { playthrough: { name: 'New Name' } }.to_json }

        it 'updates the playthrough' do
          update_playthrough
          expect(playthrough.reload.name).to eq('New Name')
        end

        it 'returns status 200' do
          update_playthrough
          expect(response.status).to eq(200)
        end

        it 'returns the playthrough in the response body' do
          update_playthrough

          # There is a weird issue with serialisation in some of the tests where the timestamps
          # on the deserialised response body differs from those on the model by '+0000' This is
          # the only way I've found to fix the tests.
          playthrough_attributes_without_timestamps = playthrough.reload.attributes.except('created_at', 'updated_at')
          response_body_without_timestamps = JSON.parse(response.body).except('created_at', 'updated_at')

          expect(response_body_without_timestamps).to eq(playthrough_attributes_without_timestamps)
        end
      end

      context 'when the params are invalid' do
        let!(:playthrough) { create(:playthrough, user:) }
        let!(:other_playthrough) { create(:playthrough, user:) }
        let(:params) { { playthrough: { name: other_playthrough.name } }.to_json }

        it 'returns status 422' do
          update_playthrough
          expect(response.status).to eq(422)
        end

        it 'returns the errors' do
          update_playthrough
          expect(response.body).to eq({ errors: ['Name must be unique'] }.to_json)
        end
      end

      context 'when the playthrough does not exist' do
        let(:playthrough) { double(id: 829_315) }
        let(:params) { { playthrough: { name: 'New Name' } }.to_json }

        it 'returns status 404' do
          update_playthrough
          expect(response.status).to eq(404)
        end

        it "doesn't return any data" do
          update_playthrough
          expect(response.body).to be_blank
        end
      end

      context 'when the playthrough belongs to another user' do
        let!(:playthrough) { create(:playthrough) }
        let(:params) { { playthrough: { name: 'New Name' } }.to_json }

        it "doesn't update the playthrough" do
          expect { update_playthrough }
            .not_to change(playthrough.reload, :name)
        end

        it 'returns status 404' do
          update_playthrough
          expect(response.status).to eq(404)
        end
      end

      context 'when something unexpected goes wrong' do
        let(:playthrough) { create(:playthrough, user:) }
        let(:params) { { playthrough: { description: 'New description' } }.to_json }

        before do
          allow_any_instance_of(Playthrough).to receive(:update).and_raise(StandardError, 'Something went horribly wrong')
        end

        it 'returns a 500 status' do
          update_playthrough
          expect(response.status).to eq(500)
        end

        it 'returns the error message' do
          update_playthrough
          expect(response.body).to eq({ errors: ['Something went horribly wrong'] }.to_json)
        end
      end
    end

    context 'when not authenticated' do
      let!(:playthrough) { create(:playthrough, user:) }
      let(:user) { create(:authenticated_user) }
      let(:params) { { playthrough: { name: 'Changed Name' } } }

      before do
        stub_unsuccessful_login
      end

      it "doesn't update the playthrough" do
        update_playthrough
        expect(playthrough.reload.name).not_to eq('Changed Name')
      end

      it 'returns status 401' do
        update_playthrough
        expect(response.status).to eq(401)
      end

      it "doesn't return any data" do
        update_playthrough
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end

  describe 'DELETE /playthroughs/:id' do
    subject(:destroy_playthrough) { delete "/playthroughs/#{playthrough.id}", headers: }

    context 'when authenticated' do
      let!(:user) { create(:authenticated_user) }

      before do
        stub_successful_login
      end

      context 'when all goes well' do
        let!(:playthrough) { create(:playthrough, user:) }

        it 'destroys the playthrough' do
          expect { destroy_playthrough }
            .to change(user.playthroughs, :count).from(1).to(0)
        end

        it 'returns status 204' do
          destroy_playthrough
          expect(response.status).to eq(204)
        end

        it "doesn't return any data" do
          destroy_playthrough
          expect(response.body).to be_blank
        end
      end

      context 'when the playthrough does not exist' do
        let(:playthrough) { double(id: 752_809) }

        it 'returns status 404' do
          destroy_playthrough
          expect(response.status).to eq(404)
        end

        it "doesn't return any data" do
          destroy_playthrough
          expect(response.body).to be_blank
        end
      end

      context 'when the playthrough belongs to another user' do
        let!(:playthrough) { create(:playthrough) }

        it "doesn't destroy the playthrough" do
          expect { destroy_playthrough }
            .not_to change(Playthrough, :count)
        end

        it 'returns status 404' do
          destroy_playthrough
          expect(response.status).to eq(404)
        end
      end

      context 'when something unexpected goes wrong' do
        let!(:playthrough) { create(:playthrough, user:) }

        before do
          allow_any_instance_of(Playthrough).to receive(:destroy!).and_raise(StandardError, 'Something went horribly wrong')
        end

        it 'returns status 500' do
          destroy_playthrough
          expect(response.status).to eq(500)
        end

        it 'returns the error in the body' do
          destroy_playthrough
          expect(response.body).to eq({ errors: ['Something went horribly wrong'] }.to_json)
        end
      end
    end

    context 'when not authenticated' do
      let!(:user) { create(:authenticated_user) }
      let!(:playthrough) { create(:playthrough, user:) }

      before do
        stub_unsuccessful_login
      end

      it "doesn't destroy the playthrough" do
        expect { destroy_playthrough }
          .not_to change(Playthrough, :count)
      end

      it 'returns status 401' do
        destroy_playthrough
        expect(response.status).to eq(401)
      end

      it "doesn't return any data" do
        destroy_playthrough
        expect(JSON.parse(response.body)).to eq({ 'errors' => ['Token validation response did not include a user'] })
      end
    end
  end
end

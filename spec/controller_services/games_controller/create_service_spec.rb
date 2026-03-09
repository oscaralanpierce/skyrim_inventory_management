# frozen_string_literal: true

require 'rails_helper'
require 'service/created_result'
require 'service/unprocessable_entity_result'
require 'service/internal_server_error_result'

RSpec.describe GamesController::CreateService do
  subject(:perform) { described_class.new(user, params).perform }

  let!(:user) { create(:user) }

  context 'when the params are valid' do
    let(:params) { { name: 'Skyrim, Baby' } }

    it 'creates a new game' do
      expect { perform }
        .to change(user.games, :count).from(0).to(1)
    end

    it 'returns a Service::CreatedResult' do
      expect(perform).to be_a(Service::CreatedResult)
    end

    it 'sets the game as the resource' do
      expect(perform.resource).to eq user.games.last
    end
  end

  context 'when the params are invalid' do
    let(:params) { { name: '$@#*$&' } }

    it "doesn't create a new game" do
      expect { perform }
        .not_to change(Game, :count)
    end

    it 'returns a Service::UnprocessableEntityResult' do
      expect(perform).to be_a(Service::UnprocessableEntityResult)
    end

    it 'sets the errors' do
      expect(perform.errors).to eq(["Name can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')"])
    end
  end

  context 'when something unexpected goes wrong' do
    let(:params) { { name: 'My Game' } }

    before { allow_any_instance_of(Game).to receive(:save).and_raise(StandardError, 'Something has gone horribly wrong') }

    it 'returns a Service::InternalServerErrorResult' do
      expect(perform).to be_a(Service::InternalServerErrorResult)
    end

    it 'sets the errors' do
      expect(perform.errors).to eq(['Something has gone horribly wrong'])
    end
  end
end

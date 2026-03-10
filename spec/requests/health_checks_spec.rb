# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'HealthChecks', type: :request do
  describe 'GET /index' do
    subject(:index) { get '/' }

    it 'returns status 200' do
      index
      expect(response.status).to eq(200)
    end

    it 'returns an empty object' do
      index
      expect(response.body).to eq('{}')
    end
  end
end

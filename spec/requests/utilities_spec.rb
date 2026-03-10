# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Utilities', type: :request do
  describe 'GET /privacy' do
    subject(:privacy) { get '/privacy' }

    it 'returns status 200' do
      privacy
      expect(response.status).to eq(200)
    end

    it 'renders the privacy policy in plain text' do
      privacy
      expect(response.headers['Content-Type']).to eq('text/plain; charset=utf-8')
    end
  end

  describe 'GET /tos' do
    subject(:tos) { get '/tos' }

    it 'returns status 200' do
      tos
      expect(response.status).to eq(200)
    end

    it 'renders the terms of service in plain text' do
      tos
      expect(response.headers['Content-Type']).to eq('text/plain; charset=utf-8')
    end
  end
end

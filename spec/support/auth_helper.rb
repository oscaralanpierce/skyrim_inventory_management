# frozen_string_literal: true

require 'webmock/rspec'

module AuthHelper
  include WebMock::API

  def stub_successful_login
    stub_request(:post, auth_uri).to_return(status: 200, body: File.read(Rails.root.join('spec', 'support', 'fixtures', 'auth', 'success.json')))
  end

  def stub_unsuccessful_login
    stub_request(:post, auth_uri).to_return(status: 200, body: File.read(Rails.root.join('spec', 'support', 'fixtures', 'auth', 'empty_users_array.json')))
  end

  def auth_uri
    "#{ApplicationController::AuthorizationService::FIREBASE_VERIFICATION_URI}?key=#{Rails.application.credentials[:google][:firebase_web_api_key]}"
  end
end

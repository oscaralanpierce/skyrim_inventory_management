# frozen_string_literal: true

require 'service/unauthorized_result'

class ApplicationController < ActionController::API
  class AuthorizationService
    FIREBASE_VERIFICATION_URI = 'https://www.googleapis.com/identitytoolkit/v3/relyingparty/getAccountInfo'

    class AmbiguousUserError < StandardError; end

    def initialize(controller, access_token)
      @controller = controller
      @access_token = access_token
    end

    def perform
      return Service::UnauthorizedResult.new(errors: 'No Google OAuth 2.0 access token found') if access_token.blank?

      token_response = connection.post {|req| req.body = { idToken: access_token }.to_json }

      if token_response.success?
        users = JSON.parse(token_response.body)['users']

        raise AmbiguousUserError.new('Token validation response did not include a user') if users.blank?
        raise AmbiguousUserError.new('Token validation response included multiple users') if users.length > 1

        controller.current_user = User.create_or_update_for_google(users.first)
        nil
      else
        Rails.logger.debug token_response.body
        Rails.logger.error "Error validating user access token: #{token_response.status}"
        Service::UnauthorizedResult.new(errors: ['Unable to validate user access token.'])
      end
    rescue StandardError => e
      Rails.logger.error "#{e.class} validating user access token: #{e.message}"
      Service::UnauthorizedResult.new(errors: [e.message])
    end

    private

    attr_reader :controller, :access_token

    def connection
      @connection ||= Faraday.new(
        url: FIREBASE_VERIFICATION_URI,
        params: { key: Rails.application.credentials[:google][:firebase_web_api_key] },
        headers: { 'Content-Type' => 'application/json' },
      )
    end
  end
end

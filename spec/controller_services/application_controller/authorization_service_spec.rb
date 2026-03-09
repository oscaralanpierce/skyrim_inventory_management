# frozen_string_literal: true

require 'rails_helper'
require 'service/unauthorized_result'

RSpec.describe ApplicationController::AuthorizationService do
  describe '#perform' do
    subject(:perform) { described_class.new(controller, token).perform }

    let(:controller) { instance_double(ApplicationController) }
    let(:faraday) { instance_double(Faraday::Connection, post: google_auth_response) }
    let(:google_auth_response) { instance_double(Faraday::Response, status:, body:, success?: success) }
    let(:token) { 'xxxxxxx' }

    before do
      allow(Faraday).to receive(:new).and_return(faraday)
      allow(controller).to receive(:current_user=)
    end

    context 'when the token is nil' do
      let(:token) { nil }
      let(:status) { nil }
      let(:success) { nil }
      let(:body) { nil }

      it 'returns a Service::UnauthorizedResult' do
        expect(perform).to be_a(Service::UnauthorizedResult)
      end

      it 'sets an error' do
        expect(perform.errors).to include 'No Google OAuth 2.0 access token found'
      end

      it "doesn't set current user" do
        perform
        expect(controller).not_to have_received(:current_user=)
      end
    end

    context 'when login is successful' do
      let(:status) { 200 }
      let(:success) { true }
      let(:body) { File.read(Rails.root.join('spec', 'support', 'fixtures', 'auth', 'success.json')) }

      context 'when a matching user exists' do
        let!(:user) { create(:authenticated_user) }

        it 'sets the current user' do
          perform
          expect(controller).to have_received(:current_user=).with(user)
        end

        it 'returns nil' do
          expect(perform).to be_nil
        end
      end

      context 'when a different user exists' do
        let!(:user) { create(:user) }

        it 'creates a new user' do
          expect { perform }
            .to change(User, :count).from(1).to(2)
        end

        it 'sets the current user' do
          perform
          expect(controller)
            .to have_received(:current_user=)
                  .with(User.find_by(uid: 'somestring')) # value from fixture
        end

        it 'returns nil' do
          expect(perform).to be_nil
        end
      end

      context 'when there are no users' do
        it 'creates a new user' do
          expect { perform }
            .to change(User, :count).from(0).to(1)
        end

        it 'sets the current user' do
          perform
          expect(controller).to have_received(:current_user=).with(User.last)
        end

        it 'returns nil' do
          expect(perform).to be_nil
        end
      end
    end

    context 'when an unexpected response body is returned' do
      let(:status) { 200 }
      let(:success) { true }

      before { allow(Rails.logger).to receive(:error) }

      context 'when there is no "users" array in the returned value' do
        let(:body) { File.read(Rails.root.join('spec', 'support', 'fixtures', 'auth', 'no_users_array.json')) }

        it "doesn't create a user" do
          expect { perform }
            .not_to change(User, :count)
        end

        it "doesn't assign a current user" do
          perform
          expect(controller).not_to have_received(:current_user=)
        end

        it 'returns a Service::UnauthorizedResult' do
          expect(perform).to be_a(Service::UnauthorizedResult)
        end

        it 'returns an informative error message' do
          expect(perform.errors).to include 'Token validation response did not include a user'
        end

        it 'logs the error' do
          perform
          expect(Rails.logger).to have_received(:error).with('ApplicationController::AuthorizationService::AmbiguousUserError validating user access token: Token validation response did not include a user')
        end
      end

      context 'when there are no users in the returned array' do
        let(:body) { File.read(Rails.root.join('spec', 'support', 'fixtures', 'auth', 'empty_users_array.json')) }

        it "doesn't create a user" do
          expect { perform }
            .not_to change(User, :count)
        end

        it "doesn't assign a current user" do
          perform
          expect(controller).not_to have_received(:current_user=)
        end

        it 'returns a Service::UnauthorizedResult' do
          expect(perform).to be_a(Service::UnauthorizedResult)
        end

        it 'returns an informative error message' do
          expect(perform.errors).to include 'Token validation response did not include a user'
        end

        it 'logs the error' do
          perform
          expect(Rails.logger).to have_received(:error).with('ApplicationController::AuthorizationService::AmbiguousUserError validating user access token: Token validation response did not include a user')
        end
      end

      context 'when the token response includes multiple users' do
        let(:body) { File.read(Rails.root.join('spec', 'support', 'fixtures', 'auth', 'multiple_users.json')) }

        it "doesn't create a user" do
          expect { perform }
            .not_to change(User, :count)
        end

        it "doesn't assign a current user" do
          perform
          expect(controller).not_to have_received(:current_user=)
        end

        it 'returns a Service::UnauthorizedResult' do
          expect(perform).to be_a(Service::UnauthorizedResult)
        end

        it 'returns an informative error message' do
          expect(perform.errors).to include 'Token validation response included multiple users'
        end

        it 'logs the error' do
          perform
          expect(Rails.logger).to have_received(:error).with('ApplicationController::AuthorizationService::AmbiguousUserError validating user access token: Token validation response included multiple users')
        end
      end
    end

    context 'when a non-200-range response is returned' do
      let(:status) { 400 }
      let(:success) { false }

      # Note: We don't actually know what an unsuccessful response body would look like
      #       because we haven't received one yet during manual testing.
      let(:body) { { error: 'Something went wrong' }.to_json }

      before do
        allow(Rails.logger).to receive(:debug)
        allow(Rails.logger).to receive(:error)
      end

      it "doesn't create a user" do
        expect { perform }
          .not_to change(User, :count)
      end

      it "doesn't assign a current user to the controller" do
        perform
        expect(controller).not_to have_received(:current_user=)
      end

      it 'returns a Service::UnauthorizedResult' do
        expect(perform).to be_a(Service::UnauthorizedResult)
      end

      it 'includes a generic error message' do
        expect(perform.errors).to include 'Unable to validate user access token.'
      end

      it 'logs the response body in debug mode' do
        perform
        expect(Rails.logger).to have_received(:debug).with(body)
      end

      it 'logs the status code' do
        perform
        expect(Rails.logger).to have_received(:error).with('Error validating user access token: 400')
      end
    end

    context 'when an unexpected error is raised' do
      let(:status) { 200 }
      let(:success) { true }
      let(:body) { 'oops' }

      before do
        allow(Rails.logger).to receive(:error)
        allow(JSON) # choosing this arbitrarily
          .to receive(:parse)
                .and_raise(StandardError.new('Something went wrong'))
      end

      it 'returns a Service::UnauthorizedResult' do
        expect(perform).to be_a(Service::UnauthorizedResult)
      end

      it 'returns the error message' do
        expect(perform.errors).to include 'Something went wrong'
      end

      it 'logs the error' do
        perform
        expect(Rails.logger).to have_received(:error).with('StandardError validating user access token: Something went wrong')
      end
    end
  end
end

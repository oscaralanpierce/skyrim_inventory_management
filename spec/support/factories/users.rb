# frozen_string_literal: true

FactoryBot.define do
  factory(:user) do
    sequence(:uid) {|n| "foobar#{n}" }
    sequence(:email) { 'foo@example.com' }
    display_name { 'Jane Doe' }

    # This factory uses data from /spec/support/fixtures/auth/success.json
    # to mock an existing user to authenticate with WebMock.
    factory :authenticated_user do
      uid { 'somestring' }
      email { 'someuser@gmail.com' }

      factory :authenticated_user_with_games do
        transient { game_count { 2 } }

        after(:create) {|user, evaluator| create_list(:game, evaluator.game_count, user:) }
      end
    end

    factory :user_with_games do
      transient { game_count { 2 } }

      after(:create) {|user, evaluator| create_list(:game, evaluator.game_count, user:) }
    end
  end
end

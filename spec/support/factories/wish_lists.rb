# frozen_string_literal: true

FactoryBot.define do
  factory :wish_list do
    game

    sequence(:title) {|n| "Wish List #{n}" }

    factory :aggregate_wish_list do
      aggregate { true }
      title { 'All Items' }
      aggregate_list_id { nil }
    end

    factory :wish_list_with_list_items do
      transient { list_item_count { 2 } }

      after(:create) {|list, evaluator| create_list(:wish_list_item, evaluator.list_item_count, list:) }
    end
  end
end

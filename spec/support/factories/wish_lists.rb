# frozen_string_literal: true

FactoryBot.define do
  factory :wish_list do
    playthrough

    sequence(:title) {|n| "Wish List #{n}" }

    factory :aggregate_wish_list do
      aggregate { true }
      title { 'All Items' }
      aggregate_list_id { nil }
    end

    factory :wish_list_with_list_items do
      transient do
        list_item_count { 2 }
      end

      after(:create) do |list, evaluator|
        create_list(:wish_list_item, evaluator.list_item_count, list:)
      end
    end
  end
end

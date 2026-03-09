# frozen_string_literal: true

FactoryBot.define do
  factory :inventory_list do
    game

    sequence(:title) {|n| "Inventory List #{n}" }

    factory :aggregate_inventory_list do
      aggregate { true }
      title { 'All Items' }
      aggregate_list_id { nil }
    end

    factory :inventory_list_with_list_items do
      transient { list_item_count { 2 } }

      after(:create) {|list, evaluator| create_list(:inventory_item, evaluator.list_item_count, list:) }
    end
  end
end

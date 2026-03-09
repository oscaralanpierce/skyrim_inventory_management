# frozen_string_literal: true

FactoryBot.define do
  factory :game do
    user

    sequence(:name) {|n| "Skyrim Game #{n}" }

    factory :game_with_wish_lists do
      transient { wish_list_count { 2 } }

      after(:create) do |game, evaluator|
        create(:aggregate_wish_list, game:)
        create_list(:wish_list, evaluator.wish_list_count, game:)
      end
    end

    factory :game_with_wish_lists_and_items do
      transient { wish_list_count { 2 } }

      after(:create) do |game, evaluator|
        wish_lists = create_list(:wish_list_with_list_items, evaluator.wish_list_count, game:)

        wish_lists.each {|list| list.list_items.each {|item| list.aggregate_list.add_item_from_child_list(item) } }
      end
    end

    factory :game_with_inventory_lists do
      transient { inventory_list_count { 2 } }

      after(:create) do |game, evaluator|
        create(:aggregate_inventory_list, game:)
        create_list(:inventory_list, evaluator.inventory_list_count, game:)
      end
    end

    factory :game_with_inventory_lists_and_items do
      transient { inventory_list_count { 2 } }

      after(:create) do |game, evaluator|
        inventory_lists = create_list(:inventory_list_with_list_items, evaluator.inventory_list_count, game:)

        inventory_lists.each {|list| list.list_items.each {|item| list.aggregate_list.add_item_from_child_list(item) } }
      end
    end

    factory :game_with_everything do
      transient do
        wish_list_count { 2 }
        inventory_list_count { 2 }
      end

      after(:create) do |game, evaluator|
        inventory_lists = create_list(:inventory_list_with_list_items, evaluator.inventory_list_count, game:)

        inventory_lists.each {|list| list.list_items.each {|item| list.aggregate_list.add_item_from_child_list(item) } }

        wish_lists = create_list(:wish_list_with_list_items, evaluator.wish_list_count, game:)

        wish_lists.each {|list| list.list_items.each {|item| list.aggregate_list.add_item_from_child_list(item) } }
      end
    end
  end
end

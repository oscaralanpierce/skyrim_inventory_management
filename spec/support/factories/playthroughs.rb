# frozen_string_literal: true

FactoryBot.define do
  factory :playthrough do
    user

    sequence(:name) {|n| "Skyrim Playthrough #{n}" }

    factory :playthrough_with_wish_lists do
      transient do
        wish_list_count { 2 }
      end

      after(:create) do |playthrough, evaluator|
        create(:aggregate_wish_list, playthrough:)
        create_list(:wish_list, evaluator.wish_list_count, playthrough:)
      end
    end

    factory :playthrough_with_wish_lists_and_items do
      transient do
        wish_list_count { 2 }
      end

      after(:create) do |playthrough, evaluator|
        wish_lists = create_list(:wish_list_with_list_items, evaluator.wish_list_count, playthrough:)

        wish_lists.each do |list|
          list.list_items.each do |item|
            list.aggregate_list.add_item_from_child_list(item)
          end
        end
      end
    end

    factory :playthrough_with_inventory_lists do
      transient do
        inventory_list_count { 2 }
      end

      after(:create) do |playthrough, evaluator|
        create(:aggregate_inventory_list, playthrough:)
        create_list(:inventory_list, evaluator.inventory_list_count, playthrough:)
      end
    end

    factory :playthrough_with_inventory_lists_and_items do
      transient do
        inventory_list_count { 2 }
      end

      after(:create) do |playthrough, evaluator|
        inventory_lists = create_list(:inventory_list_with_list_items, evaluator.inventory_list_count, playthrough:)

        inventory_lists.each do |list|
          list.list_items.each do |item|
            list.aggregate_list.add_item_from_child_list(item)
          end
        end
      end
    end

    factory :playthrough_with_everything do
      transient do
        wish_list_count { 2 }
        inventory_list_count { 2 }
      end

      after(:create) do |playthrough, evaluator|
        inventory_lists = create_list(:inventory_list_with_list_items, evaluator.inventory_list_count, playthrough:)

        inventory_lists.each do |list|
          list.list_items.each do |item|
            list.aggregate_list.add_item_from_child_list(item)
          end
        end

        wish_lists = create_list(:wish_list_with_list_items, evaluator.wish_list_count, playthrough:)

        wish_lists.each do |list|
          list.list_items.each do |item|
            list.aggregate_list.add_item_from_child_list(item)
          end
        end
      end
    end
  end
end

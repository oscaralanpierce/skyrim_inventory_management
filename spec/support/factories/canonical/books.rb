# frozen_string_literal: true

FactoryBot.define do
  factory :canonical_book, class: Canonical::Book do
    title { 'My Book' }
    sequence(:item_code) {|n| "123xxx#{n}" }
    unit_weight { 1.0 }
    book_type { 'lore book' }
    add_on { 'base' }
    purchasable { true }
    collectible { true }
    unique_item { false }
    rare_item { false }
    solstheim_only { false }
    quest_item { false }

    factory :canonical_recipe do
      book_type { 'recipe' }

      after(:create) {|recipe| create_list(:recipes_canonical_ingredient, 2, recipe:) }
    end
  end
end

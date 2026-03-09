# frozen_string_literal: true

FactoryBot.define do
  factory :canonical_clothing_item, class: Canonical::ClothingItem do
    name { 'Fine Clothes' }
    sequence(:item_code) {|n| "123xxx#{n}" }
    unit_weight { 9.9 }
    body_slot { 'body' }
    add_on { 'base' }
    collectible { true }
    purchasable { true }
    unique_item { false }
    rare_item { false }
    quest_item { false }

    trait :with_enchantments do
      after(:create) {|item| create_list(:enchantables_enchantment, 2, :with_strength, enchantable: item) }
    end
  end
end

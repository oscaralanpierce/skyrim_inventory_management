# frozen_string_literal: true

FactoryBot.define do
  factory :canonical_jewelry_item, class: Canonical::JewelryItem do
    name { 'Gold Diamond Ring' }
    sequence(:item_code) {|n| "xxx123#{n}" }
    jewelry_type { 'ring' }
    unit_weight { 37.0 }
    add_on { 'base' }
    collectible { true }
    purchasable { true }
    unique_item { false }
    rare_item { false }
    quest_item { false }
    quest_reward { false }

    trait :with_crafting_materials do
      after(:create) {|model| create_list(:canonical_material, 2, craftable: model, quantity: 1) }
    end

    trait :with_enchantments do
      after(:create) {|model| create_list(:enchantables_enchantment, 2, :with_strength, enchantable: model) }
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :canonical_armor, class: Canonical::Armor do
    name { 'Steel Plate Armor' }
    sequence(:item_code) {|n| "123abc#{n}" }
    weight { 'heavy armor' }
    body_slot { 'body' }
    unit_weight { 1.0 }
    smithing_perks { ['Steel Smithing'] }
    add_on { 'base' }
    collectible { true }
    purchasable { true }
    unique_item { false }
    rare_item { false }
    quest_item { false }

    trait :with_enchantments do
      after(:create) {|armor| create_list(:enchantables_enchantment, 2, :with_strength, enchantable: armor) }
    end
  end
end

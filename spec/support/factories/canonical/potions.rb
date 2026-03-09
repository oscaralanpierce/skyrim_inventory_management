# frozen_string_literal: true

FactoryBot.define do
  factory :canonical_potion, class: Canonical::Potion do
    name { 'Potion of Fortify Destruction' }
    sequence(:item_code) {|n| "xx123x#{n}" }
    unit_weight { 0.5 }
    add_on { 'base' }
    purchasable { true }
    unique_item { false }
    rare_item { false }
    quest_item { false }
    collectible { true }

    trait :with_associations do
      after(:create) {|potion| create_list(:canonical_potions_alchemical_property, 2, potion:) }
    end
  end
end

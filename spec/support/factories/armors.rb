# frozen_string_literal: true

FactoryBot.define do
  factory :armor do
    game

    name { 'Steel Plate Armor' }

    trait :with_enchantments do
      after(:create) {|armor| create_list(:enchantables_enchantment, 2, enchantable: armor) }
    end

    trait :with_matching_canonical do
      association :canonical_armor, strategy: :create
    end

    trait :with_enchanted_canonical do
      association :canonical_armor, factory: %i[canonical_armor with_enchantments], strategy: :create
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :weapon do
    game

    name { 'Dwarven War Axe' }

    trait :with_matching_canonical do
      association :canonical_weapon, strategy: :create
    end

    trait :with_enchanted_canonical do
      association :canonical_weapon, factory: %i[canonical_weapon with_enchantments], strategy: :create
    end

    trait :with_enchantments do
      after(:create) {|weapon| create_list(:enchantables_enchantment, 2, enchantable: weapon) }
    end

    trait :with_enchanted_canonical do
      association :canonical_weapon, factory: %i[canonical_weapon with_enchantments], strategy: :create
    end
  end
end

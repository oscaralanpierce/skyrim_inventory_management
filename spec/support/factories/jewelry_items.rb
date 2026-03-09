# frozen_string_literal: true

FactoryBot.define do
  factory :jewelry_item do
    game
    name { 'Gold Diamond Ring' }

    trait :with_matching_canonical do
      association :canonical_jewelry_item, strategy: :create
    end

    trait :with_enchanted_canonical do
      association :canonical_jewelry_item, factory: %i[canonical_jewelry_item with_enchantments], strategy: :create
    end

    trait :with_enchantments do
      after(:create) {|item| create_list(:enchantables_enchantment, 2, enchantable: item) }
    end
  end
end

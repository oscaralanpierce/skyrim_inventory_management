# frozen_string_literal: true

FactoryBot.define do
  factory :potion do
    game

    name { 'Potion of Fortify Destruction' }

    trait :with_matching_canonical do
      association :canonical_potion, strategy: :create
    end

    trait :with_canonical_and_alchemical_properties do
      association :canonical_potion, factory: %i[canonical_potion with_associations], strategy: :create
    end
  end
end

# frozen_string_literal: true

FactoryBot.define do
  factory :misc_item do
    playthrough

    name { "Wylandria's Soul Gem" }

    trait :with_matching_canonical do
      association :canonical_misc_item, strategy: :create
    end
  end
end

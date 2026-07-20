# frozen_string_literal: true

FactoryBot.define do
  factory :book do
    playthrough

    title { 'My Book' }

    factory :recipe do
      association :canonical_book, factory: :canonical_recipe, strategy: :create
    end

    trait :with_matching_canonical do
      association :canonical_book, strategy: :create
    end
  end
end

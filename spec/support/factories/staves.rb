# frozen_string_literal: true

FactoryBot.define do
  factory :staff do
    playthrough

    name { 'Staff of Chain Lightning' }
    unit_weight { 8 }

    trait :with_matching_canonical do
      association :canonical_staff
    end
  end
end

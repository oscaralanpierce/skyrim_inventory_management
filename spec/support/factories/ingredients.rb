# frozen_string_literal: true

FactoryBot.define do
  factory :ingredient do
    game

    name { 'Blue Mountain Flower' }

    trait :with_alchemical_properties do
      after(:create) {|ingredient| 4.times {|n| create(:ingredients_alchemical_property, ingredient:, priority: n + 1) } }
    end

    factory :ingredient_with_matching_canonical do
      association :canonical_ingredient, strategy: :create

      trait :with_associations do
        association :canonical_ingredient, factory: %i[canonical_ingredient with_alchemical_properties], strategy: :create
      end

      trait :with_associations_and_properties do
        association :canonical_ingredient, factory: %i[canonical_ingredient with_alchemical_properties]

        after(:create) {|model| model.canonical_ingredient.canonical_ingredients_alchemical_properties.each {|join_model| create(:ingredients_alchemical_property, ingredient: model, alchemical_property: join_model.alchemical_property, priority: join_model.priority) } }
      end
    end
  end
end

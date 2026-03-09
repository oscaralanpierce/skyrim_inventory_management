# frozen_string_literal: true

FactoryBot.define do
  factory :ingredients_alchemical_property do
    ingredient
    alchemical_property

    sequence(:priority) {|n| (n % 4) + 1 }

    trait :valid do
      association :ingredient, factory: :ingredient_with_matching_canonical, strategy: :create

      after(:build) do |model|
        matching_model = create(:canonical_ingredients_alchemical_property, ingredient: model.ingredient.canonical_ingredient, alchemical_property: model.alchemical_property, priority: 1)

        model.priority = matching_model.priority
      end
    end
  end
end

# frozen_string_literal: true

class RecipesCanonicalIngredient < ApplicationRecord
  belongs_to :recipe, polymorphic: true
  belongs_to :ingredient, class_name: 'Canonical::Ingredient'

  validates :recipe_id, uniqueness: { scope: %i[recipe_type ingredient_id], message: 'must form a unique combination with canonical ingredient' }

  validate :verify_recipe_is_recipe

  private

  def verify_recipe_is_recipe
    errors.add(:recipe, 'must be a recipe') unless recipe.recipe?
  end
end

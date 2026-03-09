# frozen_string_literal: true

module Canonical
  class IngredientsAlchemicalProperty < ApplicationRecord
    self.table_name = 'canonical_ingredients_alchemical_properties'

    belongs_to :alchemical_property
    belongs_to :ingredient, class_name: 'Canonical::Ingredient'

    validates :alchemical_property_id, uniqueness: { scope: :ingredient_id, message: 'must form a unique combination with canonical ingredient' }
    validates :priority, allow_blank: true, uniqueness: { scope: :ingredient_id, message: 'must be unique per ingredient' }, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 4, only_integer: true }
    validates :strength_modifier, allow_blank: true, numericality: { greater_than: 0 }
    validates :duration_modifier, allow_blank: true, numericality: { greater_than: 0 }
    validate :ensure_max_per_ingredient

    MAX_PER_INGREDIENT = 4

    private

    def ensure_max_per_ingredient
      return if ingredient.alchemical_properties.length < MAX_PER_INGREDIENT
      return if persisted? &&
        !ingredient_id_changed? &&
        ingredient.alchemical_properties.length == MAX_PER_INGREDIENT

      errors.add(:ingredient, "already has #{MAX_PER_INGREDIENT} alchemical properties")
    end
  end
end

# frozen_string_literal: true

class IngredientsAlchemicalProperty < ApplicationRecord
  belongs_to :ingredient
  belongs_to :alchemical_property

  validates :alchemical_property_id, uniqueness: { scope: :ingredient_id, message: 'must form a unique combination with ingredient' }
  validates :priority, allow_blank: true, uniqueness: { scope: :ingredient_id, message: 'must be unique per ingredient' }, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 4, only_integer: true }
  validate :ensure_match_exists
  validate :ensure_max_per_ingredient

  before_validation :set_attributes_from_canonical, if: -> { canonical_model.present? }

  DOES_NOT_MATCH = 'is not consistent with any ingredient that exists in Skyrim'

  def canonical_models
    return Canonical::IngredientsAlchemicalProperty.where(**attributes_to_match) if attributes_to_match.any?

    Canonical::IngredientsAlchemicalProperty.none
  end

  def canonical_model
    models = canonical_models
    models.first if models.count == 1
  end

  def strength_modifier
    return if canonical_model.blank?

    canonical_model.strength_modifier || 1
  end

  def duration_modifier
    return if canonical_model.blank?

    canonical_model.duration_modifier || 1
  end

  private

  def ensure_max_per_ingredient
    return if ingredient.alchemical_properties.length < Canonical::IngredientsAlchemicalProperty::MAX_PER_INGREDIENT
    return if persisted? &&
      !ingredient_id_changed? &&
      ingredient.alchemical_properties.length == Canonical::IngredientsAlchemicalProperty::MAX_PER_INGREDIENT

    errors.add(:ingredient, "already has #{Canonical::IngredientsAlchemicalProperty::MAX_PER_INGREDIENT} alchemical properties")
  end

  def set_attributes_from_canonical
    return if canonical_model.nil?

    self.priority = canonical_model.priority
  end

  def ensure_match_exists
    return if canonical_models.any?

    errors.add(:base, DOES_NOT_MATCH)
  end

  def attributes_to_match
    { alchemical_property_id:, ingredient_id: ingredient.canonical_models.ids, priority: }.compact
  end
end

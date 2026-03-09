# frozen_string_literal: true

class Ingredient < InGameItem
  belongs_to :canonical_ingredient, class_name: 'Canonical::Ingredient', optional: true, inverse_of: :ingredients

  has_many :ingredients_alchemical_properties, dependent: :destroy, inverse_of: :ingredient
  has_many :alchemical_properties, -> { select 'alchemical_properties.*, ingredients_alchemical_properties.priority' }, through: :ingredients_alchemical_properties

  validates :name, presence: true

  DOES_NOT_MATCH = "doesn't match an ingredient that exists in Skyrim"
  DUPLICATE_MATCH = 'is a duplicate of a unique in-game item'

  def canonical_model
    canonical_ingredient
  end

  def canonical_models
    return Canonical::Ingredient.where(id: canonical_ingredient_id) if canonical_model_matches?

    canonicals = Canonical::Ingredient.where('name ILIKE ?', name)
    canonicals = canonicals.where(**attributes_to_match) if attributes_to_match.any?

    return canonicals if canonicals.none? || alchemical_properties.none?

    ingredients_alchemical_properties.each {|join_model| canonicals = canonicals.joins(:canonical_ingredients_alchemical_properties).where('canonical_ingredients_alchemical_properties.alchemical_property_id = :property_id AND canonical_ingredients_alchemical_properties.priority = :priority', property_id: join_model.alchemical_property_id, priority: join_model.priority) }

    Canonical::Ingredient.where(id: canonicals.ids)
  end

  private

  alias_method :canonical_model=, :canonical_ingredient=

  def canonical_class
    Canonical::Ingredient
  end

  def canonical_table
    'canonical_ingredients'
  end

  def canonical_model_id
    canonical_ingredient_id
  end

  def canonical_model_id_changed?
    canonical_ingredient_id_changed?
  end

  def inverse_relationship_name
    :ingredients
  end

  def set_values_from_canonical
    return if canonical_model.nil?
    return unless canonical_model_id_changed?

    self.name = canonical_model.name
    self.unit_weight = canonical_model.unit_weight
  end

  def canonical_model_matches?
    return false if canonical_model.nil?
    return false unless name.casecmp(canonical_model.name).zero?
    return false unless unit_weight.nil? || unit_weight == canonical_model.unit_weight

    true
  end

  def attributes_to_match
    { unit_weight: }.compact
  end
end

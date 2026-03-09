# frozen_string_literal: true

class JewelryItem < EnchantableInGameItem
  belongs_to :canonical_jewelry_item, optional: true, inverse_of: :jewelry_items, class_name: 'Canonical::JewelryItem'

  validates :name, presence: true

  validates :unit_weight, allow_blank: true, numericality: { greater_than_or_equal_to: 0 }

  validate :validate_unique_canonical

  DOES_NOT_MATCH = "doesn't match any jewelry item that exists in Skyrim"

  def crafting_materials
    canonical_jewelry_item&.crafting_materials
  end

  def canonical_model
    canonical_jewelry_item
  end

  def jewelry_type
    canonical_model&.jewelry_type
  end

  private

  def canonical_class
    Canonical::JewelryItem
  end

  def canonical_table
    'canonical_jewelry_items'
  end

  def canonical_model_id
    canonical_jewelry_item_id
  end

  def canonical_model_id_changed?
    canonical_jewelry_item_id_changed?
  end

  def inverse_relationship_name
    :jewelry_items
  end

  alias_method :canonical_model=, :canonical_jewelry_item=

  def set_values_from_canonical
    return if canonical_model.nil?
    return unless canonical_model_id_changed?

    self.name = canonical_model.name
    self.unit_weight = canonical_model.unit_weight
    self.magical_effects = canonical_model.magical_effects

    set_enchantments if persisted?
  end

  def canonical_model_matches?
    return false if canonical_model.nil?
    return false unless name.casecmp(canonical_model.name).zero?
    return false unless magical_effects.nil? || magical_effects.casecmp(canonical_model.magical_effects)&.zero?
    return false unless unit_weight.nil? || unit_weight == canonical_model.unit_weight

    true
  end

  def attributes_to_match
    { unit_weight: }.compact
  end
end

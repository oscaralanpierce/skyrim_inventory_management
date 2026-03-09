# frozen_string_literal: true

class ClothingItem < EnchantableInGameItem
  belongs_to :canonical_clothing_item, optional: true, inverse_of: :clothing_items, class_name: 'Canonical::ClothingItem'

  validates :name, presence: true

  validates :unit_weight, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  def canonical_model
    canonical_clothing_item
  end

  private

  def canonical_class
    Canonical::ClothingItem
  end

  def canonical_table
    'canonical_clothing_items'
  end

  def canonical_model_id
    canonical_clothing_item_id
  end

  def canonical_model_id_changed?
    canonical_clothing_item_id_changed?
  end

  def inverse_relationship_name
    :clothing_items
  end

  alias_method :canonical_model=, :canonical_clothing_item=

  def set_values_from_canonical
    return if canonical_model.nil?
    return unless canonical_model_id_changed?

    self.name = canonical_model.name # in case casing differs
    self.unit_weight = canonical_model.unit_weight
    self.magical_effects = canonical_model.magical_effects

    set_enchantments if persisted?
  end

  def set_enchantments
    return if canonical_clothing_item.enchantments.empty?

    remove_automatically_added_enchantments!

    canonical_clothing_item.enchantables_enchantments.each {|model| enchantables_enchantments.find_or_create_by!(enchantment_id: model.enchantment_id, strength: model.strength) {|new_model| new_model.added_automatically = true } }
  end

  def clear_canonical_clothing_item
    self.canonical_clothing_item_id = nil
    remove_automatically_added_enchantments!
  end

  def canonical_model_matches?
    return false if canonical_model.nil?
    return false unless name.casecmp(canonical_model.name).zero?
    return false unless magical_effects.nil? || magical_effects.casecmp(canonical_model.magical_effects)&.zero?
    return false unless unit_weight.nil? || unit_weight == canonical_model.unit_weight

    true
  end

  def remove_automatically_added_enchantments!
    enchantables_enchantments.added_automatically.find_each(&:destroy!)
  end

  def attributes_to_match
    { unit_weight: }.compact
  end
end

# frozen_string_literal: true

class Armor < EnchantableInGameItem
  belongs_to :canonical_armor, optional: true, inverse_of: :armors, class_name: 'Canonical::Armor'

  validates :name, presence: true

  validates :weight, inclusion: { in: Canonical::Armor::ARMOR_WEIGHTS, message: 'must be "light armor" or "heavy armor"', allow_nil: true }

  validates :unit_weight, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  def canonical_model
    canonical_armor
  end

  def crafting_materials
    canonical_armor&.crafting_materials
  end

  def tempering_materials
    canonical_armor&.tempering_materials
  end

  private

  def canonical_class
    Canonical::Armor
  end

  def canonical_table
    'canonical_armors'
  end

  def canonical_model_id
    canonical_armor_id
  end

  def canonical_model_id_changed?
    canonical_armor_id_changed?
  end

  def inverse_relationship_name
    :armors
  end

  alias_method :canonical_model=, :canonical_armor=

  def set_values_from_canonical
    return if canonical_model.nil?
    return unless canonical_model_id_changed?

    self.name = canonical_model.name # in case casing differs
    self.magical_effects = canonical_model.magical_effects
    self.unit_weight = canonical_model.unit_weight
    self.weight = canonical_model.weight

    set_enchantments if persisted?
  end

  def canonical_model_matches?
    return false if canonical_model.nil?
    return false unless name.casecmp(canonical_model.name).zero?
    return false unless unit_weight.nil? || unit_weight == canonical_model.unit_weight
    return false unless magical_effects.nil? || magical_effects.casecmp(canonical_model.magical_effects)&.zero?

    true
  end

  def attributes_to_match
    { unit_weight:, weight: }.compact
  end
end

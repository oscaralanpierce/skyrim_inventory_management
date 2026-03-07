# frozen_string_literal: true

class Weapon < EnchantableInGameItem
  belongs_to :canonical_weapon,
             optional: true,
             class_name: 'Canonical::Weapon',
             inverse_of: :weapons

  validates :name, presence: true

  validates :category,
            inclusion: {
              in: Canonical::Weapon::VALID_WEAPON_TYPES.keys,
              message: 'must be "one-handed", "two-handed", or "archery"',
              allow_blank: true,
            }

  validates :weapon_type,
            inclusion: {
              in: Canonical::Weapon::VALID_WEAPON_TYPES.values.flatten,
              message: 'must be a valid type of weapon that occurs in Skyrim',
              allow_blank: true,
            }

  DOES_NOT_MATCH = "doesn't match a weapon that exists in Skyrim"
  DUPLICATE_MATCH = 'is a duplicate of a unique in-game item'

  def canonical_model
    canonical_weapon
  end

  def crafting_materials
    canonical_weapon&.crafting_materials
  end

  def tempering_materials
    canonical_weapon&.tempering_materials
  end

  private

  def canonical_class
    Canonical::Weapon
  end

  def canonical_table
    'canonical_weapons'
  end

  def canonical_model_id
    canonical_weapon_id
  end

  def canonical_model_id_changed?
    canonical_weapon_id_changed?
  end

  def inverse_relationship_name
    :weapons
  end

  alias_method :canonical_model=, :canonical_weapon=

  def set_values_from_canonical
    return if canonical_model.nil?
    return unless canonical_model_id_changed?

    self.name = canonical_model.name
    self.unit_weight = canonical_model.unit_weight
    self.category = canonical_model.category
    self.weapon_type = canonical_model.weapon_type
    self.magical_effects = canonical_model.magical_effects

    set_enchantments if persisted?
  end

  def canonical_model_matches?
    return false if canonical_model.nil?
    return false unless name.casecmp(canonical_model.name).zero?
    return false unless magical_effects.nil? || magical_effects.casecmp(canonical_model.magical_effects)&.zero?
    return false unless unit_weight.nil? || unit_weight == canonical_model.unit_weight
    return false unless category.nil? || category == canonical_model.category
    return false unless weapon_type.nil? || weapon_type == canonical_model.weapon_type

    true
  end

  def attributes_to_match
    {
      unit_weight:,
      category:,
      weapon_type:,
    }.compact
  end
end

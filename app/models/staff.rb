# frozen_string_literal: true

class Staff < InGameItem
  belongs_to :canonical_staff, optional: true, class_name: 'Canonical::Staff', inverse_of: :staves

  validates :name, presence: true

  def spells
    canonical_staff&.spells || Spell.none
  end

  def powers
    canonical_staff&.powers || Power.none
  end

  def canonical_model
    canonical_staff
  end

  private

  alias_method :canonical_model=, :canonical_staff=

  def canonical_class
    Canonical::Staff
  end

  def canonical_table
    'canonical_staves'
  end

  def canonical_model_id
    canonical_staff_id
  end

  def canonical_model_id_changed?
    canonical_staff_id_changed?
  end

  def inverse_relationship_name
    :staves
  end

  def set_values_from_canonical
    return if canonical_model.nil?
    return unless canonical_model_id_changed?

    self.name = canonical_model.name
    self.unit_weight = canonical_model.unit_weight
    self.magical_effects = canonical_model.magical_effects
  end

  def attributes_to_match
    { unit_weight: }.compact
  end

  def canonical_model_matches?
    return false if canonical_model.nil?
    return false unless name.casecmp(canonical_model.name).zero?
    return false unless magical_effects.nil? || magical_effects.casecmp(canonical_model.magical_effects)&.zero?
    return false unless unit_weight.nil? || unit_weight == canonical_model.unit_weight

    true
  end
end

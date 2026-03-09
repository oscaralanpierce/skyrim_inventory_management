# frozen_string_literal: true

class MiscItem < InGameItem
  belongs_to :canonical_misc_item, optional: true, inverse_of: :misc_items, class_name: 'Canonical::MiscItem'

  validates :name, presence: true

  def canonical_model
    canonical_misc_item
  end

  private

  alias_method :canonical_model=, :canonical_misc_item=

  def canonical_class
    Canonical::MiscItem
  end

  def canonical_table
    'canonical_misc_items'
  end

  def canonical_model_id
    canonical_misc_item_id
  end

  def canonical_model_id_changed?
    canonical_misc_item_id_changed?
  end

  def inverse_relationship_name
    :misc_items
  end

  def set_values_from_canonical
    return if canonical_model.nil?
    return unless canonical_model_id_changed?

    self.name = canonical_misc_item.name
    self.unit_weight = canonical_misc_item.unit_weight
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

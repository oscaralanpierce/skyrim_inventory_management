# frozen_string_literal: true

class InGameItem < ApplicationRecord
  self.abstract_class = true

  belongs_to :game

  validates :unit_weight, numericality: { greater_than_or_equal_to: 0, allow_nil: true }

  validate :validate_unique_canonical
  validate :ensure_canonicals_exist

  before_validation :set_canonical_model
  before_validation :set_values_from_canonical

  MUST_DEFINE = 'Models inheriting from InGameItem must define a'
  DUPLICATE_MATCH = 'is a duplicate of a unique in-game item'
  DOES_NOT_MATCH = "doesn't match any item that exists in Skyrim"

  def canonical_model
    raise NotImplementedError.new("#{MUST_DEFINE} public #canonical_model method")
  end

  def canonical_models
    return canonical_class.where(id: canonical_model_id) if canonical_model_matches?

    query = 'name ILIKE :name'
    query += ' AND (magical_effects ILIKE :magical_effects)' if model_has_magical_effects?

    magical_effects = respond_to?(:magical_effects) ? self.magical_effects : nil

    canonicals = canonical_class.where(query, name:, magical_effects:)
    attributes_to_match.any? ? canonicals.where(**attributes_to_match) : canonicals
  end

  private

  def model_has_magical_effects?
    respond_to?(:magical_effects) && !magical_effects.nil?
  end

  def canonical_class
    raise NotImplementedError.new("#{MUST_DEFINE} private #canonical_class method")
  end

  def canonical_model=(_other)
    raise NotImplementedError.new("#{MUST_DEFINE} private #canonical_model= method")
  end

  def canonical_table
    raise NotImplementedError.new("#{MUST_DEFINE} private #canonical_table method")
  end

  def canonical_model_matches?
    raise NotImplementedError.new("#{MUST_DEFINE} private #canonical_model_matches? method")
  end

  def canonical_model_id
    raise NotImplementedError.new("#{MUST_DEFINE} private #canonical_model_id method")
  end

  def canonical_model_id_changed?
    raise NotImplementedError.new("#{MUST_DEFINE} private #canonical_model_id_changed? method")
  end

  def inverse_relationship_name
    raise NotImplementedError.new("#{MUST_DEFINE} private #inverse_relationship_name method")
  end

  def set_values_from_canonical
    raise NotImplementedError.new("#{MUST_DEFINE} private #set_values_from_canonical method")
  end

  def attributes_to_match
    raise NotImplementedError.new("#{MUST_DEFINE} private #attributes_to_match method")
  end

  def set_canonical_model
    canonicals = canonical_models

    unless canonicals.count == 1
      clear_canonical_model
      return
    end

    self.canonical_model = canonicals.first
  end

  def clear_canonical_model
    self.canonical_model = nil
  end

  def validate_unique_canonical
    return unless canonical_model&.unique_item == true

    items = canonical_model.public_send(inverse_relationship_name).where(game_id:)

    return if items.count < 1
    return if items.count == 1 && items.first == self

    errors.add(:base, DUPLICATE_MATCH)
  end

  def ensure_canonicals_exist
    errors.add(:base, DOES_NOT_MATCH) if canonical_models.none?
  end
end

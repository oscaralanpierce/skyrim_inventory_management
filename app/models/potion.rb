# frozen_string_literal: true

class Potion < ApplicationRecord
  belongs_to :game
  belongs_to :canonical_potion, optional: true, class_name: 'Canonical::Potion', inverse_of: :potions

  has_many :potions_alchemical_properties, dependent: :destroy, inverse_of: :potion
  has_many :alchemical_properties, through: :potions_alchemical_properties

  validates :name, presence: true
  validates :unit_weight, numericality: { greater_than_or_equal_to: 0, allow_blank: true }

  validate :validate_unique_canonical
  validate :validate_player_created_potion, if: -> { canonical_models.none? }

  before_validation :set_canonical_potion
  after_create :add_properties_from_canonical, if: -> { canonical_potion.present? }

  DUPLICATE_MATCH = 'is a duplicate of a unique in-game item'

  def canonical_model
    canonical_potion
  end

  def canonical_models
    return Canonical::Potion.where(id: canonical_potion_id) if canonical_model_matches?

    canonicals = Canonical::Potion.where('name ILIKE ?', name)
    canonicals = canonicals.where('magical_effects ILIKE ?', magical_effects) if magical_effects.present?

    return canonicals if canonicals.blank? || alchemical_properties.none?

    ids = canonicals.joins(:canonical_potions_alchemical_properties).where(association_query).group('canonical_potions.id').having('COUNT(*) >= ?', potions_alchemical_properties.added_manually.length).ids

    Canonical::Potion.where(id: ids)
  end

  private

  def set_canonical_potion
    canonicals = canonical_models

    unless canonicals.count == 1
      clear_canonical_potion
      return
    end

    self.canonical_potion = canonicals.first
    self.name = canonical_potion.name
    self.unit_weight = canonical_potion.unit_weight
    self.magical_effects = canonical_potion.magical_effects

    add_properties_from_canonical if persisted? && canonical_potion_id_changed?
  end

  def clear_canonical_potion
    self.canonical_potion_id = nil
    remove_automatically_added_alchemical_properties!
  end

  def validate_unique_canonical
    return unless canonical_potion&.unique_item

    potions = canonical_potion.potions.where(game_id:)

    return if potions.count < 1
    return if potions.count == 1 && potions.first == self

    errors.add(:base, DUPLICATE_MATCH)
  end

  def canonical_model_matches?
    return false if canonical_model.nil?
    return false unless name.casecmp(canonical_model.name).zero?
    return false unless magical_effects.nil? || magical_effects.casecmp(canonical_model.magical_effects)&.zero?

    if alchemical_properties.any?
      potions_alchemical_properties.each do |prop|
        return false unless canonical_has_matching_property?(prop)
      end
    end

    true
  end

  def add_properties_from_canonical
    return if canonical_model.nil?

    remove_automatically_added_alchemical_properties!

    canonical_model.canonical_potions_alchemical_properties.each {|join_model| potions_alchemical_properties.find_or_create_by!(alchemical_property_id: join_model.alchemical_property_id, strength: join_model.strength, duration: join_model.duration) {|new_model| new_model.added_automatically = true } }
  end

  def canonical_has_matching_property?(join_model)
    canonical_model.canonical_potions_alchemical_properties.find_by(alchemical_property_id: join_model.alchemical_property_id, strength: join_model.strength, duration: join_model.duration).present?
  end

  def association_query
    properties_to_match = potions_alchemical_properties.added_manually.map {|prop| { strength: prop.strength, duration: prop.duration, alchemical_property_id: prop.alchemical_property_id } }

    conditions = properties_to_match.map do |prop|
      strength_condition = if prop[:strength].nil?
                             'canonical_potions_alchemical_properties.strength IS NULL'
                           else
                             "canonical_potions_alchemical_properties.strength = #{prop[:strength]}"
                           end

      duration_condition = if prop[:duration].nil?
                             'canonical_potions_alchemical_properties.duration IS NULL'
                           else
                             "canonical_potions_alchemical_properties.duration = #{prop[:duration]}"
                           end

      conditions_array = [strength_condition, duration_condition, "canonical_potions_alchemical_properties.alchemical_property_id = #{prop[:alchemical_property_id]}"]

      "(#{conditions_array.join(' AND ')})"
    end

    conditions.join(' OR ')
  end

  def validate_player_created_potion
    if player_created_potion_names.include?(name&.downcase)
      self.name = Titlecase.titleize(name)
    else
      errors.add(:name, 'must be a valid potion or poison name')
    end
  end

  def player_created_potion_names
    @player_created_potion_names ||= begin
      strings = AlchemicalProperty.pluck(:effect_type, :name).map {|effect_type, name| "#{effect_type} of #{name.downcase}" }

      strings.uniq
    end
  end

  def remove_automatically_added_alchemical_properties!
    potions_alchemical_properties.added_automatically.find_each(&:destroy!)
  end
end

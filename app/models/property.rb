# frozen_string_literal: true

require 'skyrim'

class Property < ApplicationRecord
  belongs_to :game
  belongs_to :canonical_property, class_name: 'Canonical::Property'

  has_many :wish_lists, dependent: nil
  has_many :inventory_lists, dependent: nil

  validates :canonical_property,
            uniqueness: {
              scope: :game_id,
              message: 'must be unique per game',
            }

  validates :name,
            presence: true,
            inclusion: {
              in: Canonical::Property::VALID_NAMES,
              message: "must be an ownable property in Skyrim, or the Arch-Mage's Quarters",
            },
            uniqueness: {
              scope: :game_id,
              message: 'must be unique per game',
            }

  validates :hold,
            presence: true,
            inclusion: {
              in: Skyrim::HOLDS,
              message: 'must be one of the nine Skyrim holds, or Solstheim',
            },
            uniqueness: {
              scope: :game_id,
              message: 'must be unique per game',
            }

  validates :city,
            inclusion: {
              in: Canonical::Property::VALID_CITIES,
              message: 'must be a Skyrim city in which an ownable property is located',
              allow_blank: true,
            },
            uniqueness: {
              scope: :game_id,
              message: 'must be unique per game if present',
              allow_nil: true,
            }

  validate :ensure_max, on: :create, if: :count_is_max
  validate :ensure_alchemy_lab_available
  validate :ensure_arcane_enchanter_available
  validate :ensure_forge_available
  validate :ensure_apiary_available
  validate :ensure_grain_mill_available
  validate :ensure_fish_hatchery_available

  validate :ensure_matches_canonical_property

  validates_with HomesteadValidator

  before_validation :set_canonical_model
  before_validation :set_values_from_canonical

  DOES_NOT_MATCH = "doesn't match any ownable property that exists in Skyrim"
  HOMESTEADS = [
    'lakeview manor',
    'heljarchen hall',
    'windstad manor',
  ].freeze

  def canonical_model
    canonical_property
  end

  def homestead?
    HOMESTEADS.include?(name&.downcase)
  end

  private

  def set_canonical_model
    return if canonical_model_matches?

    self.canonical_property = Canonical::Property.find_by('name ILIKE ?', name)
  end

  def set_values_from_canonical
    return if canonical_property.nil?

    self.name = canonical_property.name
    self.city = canonical_property.city
    self.hold = canonical_property.hold
  end

  def ensure_max
    Rails.logger.error("Cannot create property \"#{name}\" in hold \"#{hold}\": this game already has #{Canonical::Property::TOTAL_PROPERTY_COUNT} properties")
    errors.add(:game, 'already has max number of ownable properties')
  end

  def count_is_max
    game.present? && game.properties.count == Canonical::Property::TOTAL_PROPERTY_COUNT
  end

  def ensure_alchemy_lab_available
    return if canonical_property&.alchemy_lab_available == true || !has_alchemy_lab

    errors.add(:has_alchemy_lab, 'cannot be true because this property cannot have an alchemy lab in Skyrim')
  end

  def ensure_arcane_enchanter_available
    return if canonical_property&.arcane_enchanter_available == true || !has_arcane_enchanter

    errors.add(:has_arcane_enchanter, 'cannot be true because this property cannot have an arcane enchanter in Skyrim')
  end

  def ensure_forge_available
    return if canonical_property&.forge_available == true || !has_forge

    errors.add(:has_forge, 'cannot be true because this property cannot have a forge in Skyrim')
  end

  def ensure_apiary_available
    return if canonical_property&.apiary_available == true || !has_apiary

    errors.add(:has_apiary, 'cannot be true because this property cannot have an apiary in Skyrim')
  end

  def ensure_grain_mill_available
    return if canonical_property&.grain_mill_available == true || !has_grain_mill

    errors.add(:has_grain_mill, 'cannot be true because this property cannot have a grain mill in Skyrim')
  end

  def ensure_fish_hatchery_available
    return if canonical_property&.fish_hatchery_available == true || !has_fish_hatchery

    errors.add(:has_fish_hatchery, 'cannot be true because this property cannot have a fish hatchery in Skyrim')
  end

  def ensure_matches_canonical_property
    errors.add(:base, DOES_NOT_MATCH) if canonical_model.nil?
  end

  def canonical_model_matches?
    return false if canonical_model.nil?
    return false unless name&.casecmp(canonical_model.name)&.zero?
    return false unless hold.nil? || hold == canonical_model.hold
    return false unless city.nil? || city == canonical_model.city

    true
  end
end

# frozen_string_literal: true

class AlchemicalProperty < ApplicationRecord
  VALID_STRENGTH_UNITS = %w[point percentage level].freeze
  VALID_EFFECT_TYPES = %w[potion poison].freeze

  has_many :canonical_ingredients_alchemical_properties, dependent: :destroy, class_name: 'Canonical::IngredientsAlchemicalProperty'
  has_many :canonical_ingredients, through: :canonical_ingredients_alchemical_properties, source: :ingredient

  has_many :canonical_potions_alchemical_properties, dependent: :destroy, class_name: 'Canonical::PotionsAlchemicalProperty'
  has_many :canonical_potions, through: :canonical_potions_alchemical_properties, source: :potion

  has_many :ingredients_alchemical_properties, dependent: :destroy, class_name: '::IngredientsAlchemicalProperty'
  has_many :ingredients, through: :ingredients_alchemical_properties

  has_many :potions_alchemical_properties, dependent: :destroy, class_name: '::PotionsAlchemicalProperty'
  has_many :potions, through: :potions_alchemical_properties

  validates :name, presence: true, uniqueness: { message: 'must be unique' }
  validates :description, presence: true
  validates :strength_unit, inclusion: { in: VALID_STRENGTH_UNITS, message: 'must be "point", "percentage", or the "level" of affected targets', allow_blank: true }
  validates :effect_type, presence: true, inclusion: { in: VALID_EFFECT_TYPES, message: 'must be "potion" or "poison"' }
  validates :add_on, presence: true, inclusion: { in: Canonical::SUPPORTED_ADD_ONS, message: Canonical::UNSUPPORTED_ADD_ON_MESSAGE }

  def self.unique_identifier
    :name
  end
end

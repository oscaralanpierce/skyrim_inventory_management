# frozen_string_literal: true

require 'skyrim'

class Enchantment < ApplicationRecord
  ENCHANTABLE_WEAPONS = ['sword', 'mace', 'war axe', 'greatsword', 'warhammer', 'battleaxe', 'dagger', 'bow', 'crossbow', 'staff', 'other'].freeze

  ENCHANTABLE_APPAREL_ITEMS = %w[head chest hands feet shield circlet amulet ring].freeze

  ENCHANTABLE_ITEMS = (ENCHANTABLE_WEAPONS + ENCHANTABLE_APPAREL_ITEMS).freeze

  STRENGTH_UNITS = %w[percentage point second level].freeze

  has_many :enchantables_enchantments, dependent: :destroy
  has_many :enchantables, through: :enchantables_enchantments

  validates :name, presence: true, uniqueness: { message: 'must be unique' }
  validates :strength_unit, inclusion: { in: STRENGTH_UNITS, message: 'must be "point", "percentage", "second", or the "level" of affected targets', allow_blank: true }
  validates :school, presence: false, inclusion: { in: Skyrim::MAGIC_SCHOOLS, message: 'must be a valid school of magic', allow_blank: true }
  validates :add_on, presence: true, inclusion: { in: Canonical::SUPPORTED_ADD_ONS, message: Canonical::UNSUPPORTED_ADD_ON_MESSAGE }
  validate :validate_enchantable_items

  def self.unique_identifier
    :name
  end

  private

  def validate_enchantable_items
    errors.add(:enchantable_items, 'must consist of valid enchantable item types') unless enchantable_items.all? {|item| ENCHANTABLE_ITEMS.include?(item) }
  end
end

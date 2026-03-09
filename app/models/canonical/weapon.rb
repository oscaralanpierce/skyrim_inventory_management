# frozen_string_literal: true

require 'skyrim'

module Canonical
  class Weapon < ApplicationRecord
    self.table_name = 'canonical_weapons'

    VALID_WEAPON_TYPES = { 'one-handed' => ['dagger', 'mace', 'other', 'sword', 'war axe'].freeze, 'two-handed' => %w[battleaxe greatsword warhammer].freeze, 'archery' => %w[arrow bolt bow crossbow].freeze }.freeze

    has_many :enchantables_enchantments, dependent: :destroy, as: :enchantable
    has_many :enchantments, -> { select 'enchantments.*, enchantables_enchantments.strength as strength' }, through: :enchantables_enchantments

    has_many :canonical_powerables_powers, dependent: :destroy, class_name: 'Canonical::PowerablesPower', as: :powerable
    has_many :powers, through: :canonical_powerables_powers

    has_many :canonical_crafting_materials, dependent: :destroy, as: :craftable, class_name: 'Canonical::Material'
    has_many :crafting_weapons, through: :canonical_crafting_materials, source: :source_material, source_type: 'Canonical::Weapon'
    has_many :crafting_ingredients, through: :canonical_crafting_materials, source: :source_material, source_type: 'Canonical::Ingredient'
    has_many :crafting_raw_materials, through: :canonical_crafting_materials, source: :source_material, source_type: 'Canonical::RawMaterial'

    has_many :canonical_tempering_materials, dependent: :destroy, as: :temperable, class_name: 'Canonical::Material'
    has_many :tempering_raw_materials, through: :canonical_tempering_materials, source: :source_material, source_type: 'Canonical::RawMaterial'
    has_many :tempering_ingredients, through: :canonical_tempering_materials, source: :source_material, source_type: 'Canonical::Ingredient'

    has_many :weapons, inverse_of: :canonical_weapon, dependent: :nullify, foreign_key: 'canonical_weapon_id', class_name: '::Weapon'

    validates :name, presence: true
    validates :item_code, presence: true, uniqueness: { message: 'must be unique' }
    validates :category, presence: true, inclusion: { in: VALID_WEAPON_TYPES.keys, message: 'must be "one-handed", "two-handed", or "archery"' }
    validates :weapon_type, presence: true, inclusion: { in: VALID_WEAPON_TYPES.values.flatten, message: 'must be a valid type of weapon that occurs in Skyrim' }
    validates :base_damage, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
    validates :unit_weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :max_quantity, presence: false, numericality: { greater_than: 0, only_integer: true, allow_nil: true }
    validates :add_on, presence: true, inclusion: { in: SUPPORTED_ADD_ONS, message: UNSUPPORTED_ADD_ON_MESSAGE }
    validates :collectible, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :purchasable, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :unique_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :rare_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :quest_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :leveled, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :enchantable, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }

    validate :verify_category_type_combination
    validate :verify_all_smithing_perks_valid
    validate :validate_uniqueness, if: -> { unique_item == true || max_quantity == 1 }

    before_validation :upcase_item_code, if: :item_code_changed?

    def self.unique_identifier
      :item_code
    end

    def crafting_materials
      crafting_raw_materials + crafting_weapons + crafting_ingredients
    end

    def tempering_materials
      tempering_raw_materials + tempering_ingredients
    end

    private

    def verify_category_type_combination
      errors.add(:weapon_type, "is not included in category \"#{category}\"") unless VALID_WEAPON_TYPES[category]&.include?(weapon_type)
    end

    def verify_all_smithing_perks_valid
      smithing_perks&.each do |perk|
        errors.add(:smithing_perks, "\"#{perk}\" is not a valid smithing perk") unless Skyrim::SMITHING_PERKS.include?(perk)
      end
    end

    def validate_uniqueness
      errors.add(:unique_item, 'must be true if max quantity is 1') if max_quantity == 1 && !unique_item
      errors.add(:unique_item, 'must correspond to a max quantity of 1') if unique_item == true && max_quantity != 1
      errors.add(:rare_item, 'must be true if item is unique') unless rare_item == true
    end

    def upcase_item_code
      item_code.upcase!
    end
  end
end

# frozen_string_literal: true

require 'skyrim'

module Canonical
  class Armor < ApplicationRecord
    self.table_name = 'canonical_armors'

    ARMOR_WEIGHTS = ['light armor', 'heavy armor'].freeze

    has_many :enchantables_enchantments, dependent: :destroy, as: :enchantable
    has_many :enchantments, -> { select 'enchantments.*, enchantables_enchantments.strength as strength' }, through: :enchantables_enchantments, source: :enchantment

    has_many :canonical_crafting_materials, dependent: :destroy, as: :craftable, class_name: 'Canonical::Material'
    has_many :crafting_ingredients, through: :canonical_crafting_materials, source: :source_material, source_type: 'Canonical::Ingredient'
    has_many :crafting_raw_materials, through: :canonical_crafting_materials, source: :source_material, source_type: 'Canonical::RawMaterial'

    has_many :canonical_tempering_materials, dependent: :destroy, as: :temperable, class_name: 'Canonical::Material'
    has_many :tempering_raw_materials, through: :canonical_tempering_materials, source: :source_material, source_type: 'Canonical::RawMaterial'
    has_many :tempering_ingredients, through: :canonical_tempering_materials, source: :source_material, source_type: 'Canonical::Ingredient'

    has_many :armors, inverse_of: :canonical_armor, dependent: :nullify, foreign_key: 'canonical_armor_id', class_name: '::Armor'

    validates :name, presence: true
    validates :item_code, presence: true, uniqueness: { message: 'must be unique' }
    validates :weight, presence: true, inclusion: { in: ARMOR_WEIGHTS, message: 'must be "light armor" or "heavy armor"' }
    validates :body_slot, presence: true, inclusion: { in: %w[head body hands feet hair shield], message: 'must be "head", "body", "hands", "feet", "hair", or "shield"' }
    validates :unit_weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :max_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1, allow_nil: true, message: 'must be an integer of at least 1' }
    validates :add_on, presence: true, inclusion: { in: SUPPORTED_ADD_ONS, message: UNSUPPORTED_ADD_ON_MESSAGE }
    validates :purchasable, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :collectible, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :enchantable, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :leveled, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :unique_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :rare_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :quest_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :quest_reward, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }

    validate :verify_all_smithing_perks_valid
    validate :validate_uniqueness, if: -> { unique_item == true || max_quantity == 1 }

    before_validation :upcase_item_code, if: :item_code_changed?

    def self.unique_identifier
      :item_code
    end

    def crafting_materials
      crafting_raw_materials + crafting_ingredients
    end

    def tempering_materials
      tempering_raw_materials + tempering_ingredients
    end

    private

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

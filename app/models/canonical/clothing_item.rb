# frozen_string_literal: true

module Canonical
  class ClothingItem < ApplicationRecord
    self.table_name = 'canonical_clothing_items'

    BODY_SLOTS = %w[head hands body feet].freeze

    has_many :enchantables_enchantments, dependent: :destroy, as: :enchantable
    has_many :enchantments, -> { select 'enchantments.*, enchantables_enchantments.strength as strength' }, through: :enchantables_enchantments

    has_many :clothing_items, inverse_of: :canonical_clothing_item, dependent: :nullify, foreign_key: 'canonical_clothing_item_id', class_name: '::ClothingItem'

    validates :name, presence: true
    validates :item_code, presence: true, uniqueness: { message: 'must be unique' }
    validates :unit_weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :body_slot, presence: true, inclusion: { in: BODY_SLOTS, message: 'must be "head", "hands", "body", or "feet"' }
    validates :add_on, presence: true, inclusion: { in: SUPPORTED_ADD_ONS, message: UNSUPPORTED_ADD_ON_MESSAGE }
    validates :max_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1, message: 'must be an integer of at least 1', allow_nil: true }
    validates :collectible, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :purchasable, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :unique_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :rare_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :quest_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :enchantable, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }

    validate :validate_uniqueness, if: -> { unique_item == true || max_quantity == 1 }

    before_validation :upcase_item_code, if: :item_code_changed?

    def self.unique_identifier
      :item_code
    end

    private

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

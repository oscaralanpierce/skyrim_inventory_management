# frozen_string_literal: true

module Canonical
  class MiscItem < ApplicationRecord
    self.table_name = 'canonical_misc_items'

    include Canonical
    VALID_ITEM_TYPES = ['animal part', 'book', 'daedric artifact', 'dragon claw', 'Dwemer artifact', 'gemstone', 'key', 'larceny trophy', 'map', 'miscellaneous', 'paragon', 'pelt'].freeze

    has_many :misc_items, inverse_of: :canonical_misc_item, dependent: :nullify, foreign_key: 'canonical_misc_item_id', class_name: '::MiscItem'

    validates :name, presence: true
    validates :item_code, presence: true, uniqueness: { message: 'must be unique' }
    validates :unit_weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :item_types, presence: true
    validates :add_on, presence: true, inclusion: { in: SUPPORTED_ADD_ONS, message: UNSUPPORTED_ADD_ON_MESSAGE }
    validates :max_quantity, numericality: { greater_than_or_equal_to: 1, only_integer: true, message: 'must be an integer of at least 1', allow_nil: true }

    validate :validate_item_types
    validate :validate_boolean_values
    validate :validate_uniqueness, if: -> { unique_item == true || max_quantity == 1 }

    before_validation :upcase_item_code, if: -> { item_code_changed? }

    def self.unique_identifier
      :item_code
    end

    private

    def validate_item_types
      errors.add(:item_types, 'must include at least one item type') if item_types.blank?
      errors.add(:item_types, 'can only include valid item types') unless item_types&.all? {|type| VALID_ITEM_TYPES.include?(type) }
    end

    def validate_boolean_values
      errors.add(:collectible, BOOLEAN_VALIDATION_MESSAGE) unless boolean?(collectible)
      errors.add(:purchasable, BOOLEAN_VALIDATION_MESSAGE) unless boolean?(purchasable)
      errors.add(:unique_item, BOOLEAN_VALIDATION_MESSAGE) unless boolean?(unique_item)
      errors.add(:rare_item, BOOLEAN_VALIDATION_MESSAGE) unless boolean?(rare_item)
      errors.add(:quest_item, BOOLEAN_VALIDATION_MESSAGE) unless boolean?(quest_item)
      errors.add(:quest_reward, BOOLEAN_VALIDATION_MESSAGE) unless boolean?(quest_reward)
    end

    def validate_uniqueness
      errors.add(:unique_item, 'must be true if max quantity is 1') if unique_item == false && max_quantity == 1
      errors.add(:unique_item, 'must correspond to a max quantity of 1') if unique_item == true && max_quantity != 1
      errors.add(:rare_item, 'must be true if item is unique') unless rare_item == true
    end

    def upcase_item_code
      item_code.upcase!
    end
  end
end

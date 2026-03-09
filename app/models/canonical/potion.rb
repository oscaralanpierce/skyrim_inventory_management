# frozen_string_literal: true

module Canonical
  class Potion < ApplicationRecord
    self.table_name = 'canonical_potions'

    has_many :canonical_potions_alchemical_properties, dependent: :destroy, class_name: 'Canonical::PotionsAlchemicalProperty', inverse_of: :potion
    has_many :alchemical_properties, through: :canonical_potions_alchemical_properties

    has_many :potions, inverse_of: :canonical_potion, dependent: :nullify, foreign_key: :canonical_potion_id, class_name: '::Potion'

    validates :name, presence: true
    validates :item_code, presence: true, uniqueness: { message: 'must be unique' }
    validates :unit_weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :add_on, presence: true, inclusion: { in: SUPPORTED_ADD_ONS, message: UNSUPPORTED_ADD_ON_MESSAGE }
    validates :max_quantity, numericality: { only_integer: true, greater_than: 0, allow_nil: true }

    validate :validate_boolean_values
    validate :validate_uniqueness, if: -> { unique_item == true || max_quantity == 1 }

    before_validation :upcase_item_code, if: :item_code_changed?

    include Canonical

    def self.unique_identifier
      :item_code
    end

    private

    def validate_boolean_values
      errors.add(:purchasable, BOOLEAN_VALIDATION_MESSAGE) unless boolean?(purchasable)
      errors.add(:unique_item, BOOLEAN_VALIDATION_MESSAGE) unless boolean?(unique_item)
      errors.add(:rare_item, BOOLEAN_VALIDATION_MESSAGE) unless boolean?(rare_item)
      errors.add(:quest_item, BOOLEAN_VALIDATION_MESSAGE) unless boolean?(quest_item)
      errors.add(:collectible, BOOLEAN_VALIDATION_MESSAGE) unless boolean?(collectible)
    end

    def validate_uniqueness
      errors.add(:unique_item, 'must be true if max quantity is 1') if max_quantity == 1 && !unique_item
      errors.add(:unique_item, 'must correspond to max quantity of 1') if unique_item == true && max_quantity != 1
      errors.add(:rare_item, 'must be true if item is unique') unless rare_item == true
    end

    def upcase_item_code
      item_code.upcase!
    end
  end
end

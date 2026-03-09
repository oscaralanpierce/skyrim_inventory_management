# frozen_string_literal: true

require 'skyrim'

module Canonical
  class Staff < ApplicationRecord
    self.table_name = 'canonical_staves'

    has_many :canonical_powerables_powers, dependent: :destroy, class_name: 'Canonical::PowerablesPower', as: :powerable
    has_many :powers, through: :canonical_powerables_powers

    has_many :canonical_staves_spells, dependent: :destroy, class_name: 'Canonical::StavesSpell', inverse_of: :staff
    has_many :spells, through: :canonical_staves_spells

    has_many :staves, inverse_of: :canonical_staff, dependent: :nullify, foreign_key: :canonical_staff_id, class_name: '::Staff'

    validates :name, presence: true
    validates :item_code, presence: true, uniqueness: { message: 'must be unique' }
    validates :max_quantity, presence: false, numericality: { greater_than: 0, only_integer: true, allow_nil: true }
    validates :unit_weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :base_damage, presence: true, numericality: { greater_than_or_equal_to: 0, only_integer: true }
    validates :school, inclusion: { in: Skyrim::MAGIC_SCHOOLS, message: 'must be a valid school of magic', allow_blank: true }
    validates :add_on, presence: true, inclusion: { in: SUPPORTED_ADD_ONS, message: UNSUPPORTED_ADD_ON_MESSAGE }
    validates :collectible, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :daedric, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :purchasable, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :unique_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :rare_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :quest_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :leveled, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }

    validate :validate_uniqueness, if: -> { unique_item == true || max_quantity == 1 }

    before_validation :upcase_item_code, if: -> { item_code_changed? }

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

# frozen_string_literal: true

module Canonical
  class Ingredient < ApplicationRecord
    self.table_name = 'canonical_ingredients'

    VALID_TYPES = %w[common uncommon rare add_on].freeze
    TYPE_VALIDATION_MESSAGE = 'must be "common", "uncommon", "rare", or "add_on"'

    has_many :canonical_ingredients_alchemical_properties, dependent: :destroy, class_name: 'Canonical::IngredientsAlchemicalProperty', inverse_of: :ingredient
    has_many :alchemical_properties, -> { select 'alchemical_properties.*, canonical_ingredients_alchemical_properties.priority' }, through: :canonical_ingredients_alchemical_properties

    has_many :recipes_canonical_ingredients, dependent: :destroy, class_name: 'RecipesCanonicalIngredient', inverse_of: :ingredient
    has_many :recipes, through: :recipes_canonical_ingredients, source: :recipe

    has_many :ingredients, dependent: :nullify, class_name: '::Ingredient', foreign_key: 'canonical_ingredient_id', inverse_of: :canonical_ingredient

    validates :name, presence: true
    validates :item_code, presence: true, uniqueness: { message: 'must be unique' }
    validates :ingredient_type, inclusion: { in: VALID_TYPES, message: TYPE_VALIDATION_MESSAGE, allow_blank: true }
    validates :unit_weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :add_on, presence: true, inclusion: { in: SUPPORTED_ADD_ONS, message: UNSUPPORTED_ADD_ON_MESSAGE }
    validates :max_quantity, numericality: { greater_than_or_equal_to: 1, only_integer: true, message: 'must be an integer of at least 1', allow_nil: true }
    validates :collectible, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :purchasable, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :purchase_requires_perk, inclusion: { in: BOOLEAN_VALUES, message: "#{BOOLEAN_VALIDATION_MESSAGE} if purchasable is true" }, if: -> { purchasable == true }
    validates :unique_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :rare_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :quest_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }

    validate :validate_ingredient_type_not_set, if: -> { purchasable == false }
    validate :validate_ingredient_type_set, if: -> { purchasable == true }
    validate :validate_purchase_requires_perk
    validate :validate_uniqueness, if: -> { unique_item == true || max_quantity == 1 }

    before_validation :upcase_item_code, if: :item_code_changed?

    def self.unique_identifier
      :item_code
    end

    private

    def validate_ingredient_type_not_set
      errors.add(:ingredient_type, 'can only be set for purchasable ingredients') unless ingredient_type.nil?
    end

    def validate_ingredient_type_set
      errors.add(:ingredient_type, "can't be blank for purchasable ingredients") if ingredient_type.blank?
    end

    def validate_purchase_requires_perk
      errors.add(:purchase_requires_perk, "can't be set if purchasable is false") if purchasable == false && !purchase_requires_perk.nil?
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

# frozen_string_literal: true

require 'skyrim'

module Canonical
  class Book < ApplicationRecord
    self.table_name = 'canonical_books'

    BOOK_TYPES = ['Black Book', 'document', 'Elder Scroll', 'journal', 'letter', 'lore book', 'quest book', 'recipe', 'skill book', 'treasure map'].freeze

    has_many :recipes_canonical_ingredients, dependent: :destroy, inverse_of: :recipe, foreign_key: 'recipe_id'
    has_many :canonical_ingredients, through: :recipes_canonical_ingredients, class_name: 'Canonical::Ingredient', source: :ingredient

    has_many :books, dependent: :nullify, class_name: '::Book', inverse_of: :canonical_book, foreign_key: 'canonical_book_id'

    validates :title, presence: true
    validates :item_code, presence: true, uniqueness: { message: 'must be unique' }
    validates :unit_weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :book_type, inclusion: { in: BOOK_TYPES, message: 'must be a book type that exists in Skyrim' }
    validates :skill_name, inclusion: { in: Skyrim::SKILLS, message: 'must be a skill that exists in Skyrim', allow_blank: true }
    validates :add_on, presence: true, inclusion: { in: SUPPORTED_ADD_ONS, message: UNSUPPORTED_ADD_ON_MESSAGE }
    validates :max_quantity, numericality: { only_integer: true, greater_than_or_equal_to: 1, allow_nil: true, message: 'must be an integer of at least 1' }
    validates :purchasable, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :collectible, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :unique_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :rare_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :solstheim_only, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }
    validates :quest_item, inclusion: { in: BOOLEAN_VALUES, message: BOOLEAN_VALIDATION_MESSAGE }

    validate :validate_skill_name_presence
    validate :validate_uniqueness, if: -> { unique_item == true || max_quantity == 1 }

    before_validation :upcase_item_code, if: :item_code_changed?

    def self.unique_identifier
      :item_code
    end

    def recipe?
      book_type == 'recipe'
    end

    private

    def validate_skill_name_presence
      if book_type == 'skill book'
        errors.add(:skill_name, "can't be blank for skill books") if skill_name.blank?
      elsif skill_name.present?
        errors.add(:skill_name, 'can only be defined for skill books')
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

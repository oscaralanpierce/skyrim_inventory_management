# frozen_string_literal: true

module Canonical
  class RawMaterial < ApplicationRecord
    self.table_name = 'canonical_raw_materials'

    has_many :materials, dependent: :destroy, class_name: 'Canonical::Material', as: :source_material
    has_many :craftable_weapons, through: :materials, source: :craftable, source_type: 'Canonical::Weapon'
    has_many :temperable_weapons, through: :materials, source: :temperable, source_type: 'Canonical::Weapon'
    has_many :craftable_armors, through: :materials, source: :craftable, source_type: 'Canonical::Armor'
    has_many :temperable_armors, through: :materials, source: :temperable, source_type: 'Canonical::Armor'
    has_many :jewelry_items, through: :materials, source: :craftable, source_type: 'Canonical::JewelryItem'

    validates :name, presence: true
    validates :item_code, presence: true, uniqueness: { message: 'must be unique' }
    validates :unit_weight, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :add_on, presence: true, inclusion: { in: SUPPORTED_ADD_ONS, message: UNSUPPORTED_ADD_ON_MESSAGE }

    before_validation :upcase_item_code, if: :item_code_changed?

    def self.unique_identifier
      :item_code
    end

    def craftable_items
      craftable_weapons + craftable_armors + jewelry_items
    end

    def temperable_items
      temperable_weapons + temperable_armors
    end

    private

    def upcase_item_code
      item_code.upcase!
    end
  end
end

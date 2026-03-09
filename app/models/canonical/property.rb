# frozen_string_literal: true

require 'skyrim'

module Canonical
  class Property < ApplicationRecord
    self.table_name = 'canonical_properties'

    has_many :properties, dependent: :destroy, class_name: '::Property', inverse_of: :canonical_property, foreign_key: :canonical_property_id

    TOTAL_PROPERTY_COUNT = 10

    VALID_NAMES = ["Arch-Mage's Quarters", 'Breezehome', 'Heljarchen Hall', 'Hjerim', 'Honeyside', 'Lakeview Manor', 'Proudspire Manor', 'Severin Manor', 'Vlindrel Hall', 'Windstad Manor'].freeze

    VALID_CITIES = ['Markarth', 'Raven Rock', 'Riften', 'Solitude', 'Whiterun', 'Windhelm', 'Winterhold'].freeze

    validate :ensure_max, on: :create, if: :count_is_max

    validates :name, presence: true, inclusion: { in: VALID_NAMES, message: "must be an ownable property in Skyrim, or the Arch-Mage's Quarters" }, uniqueness: { message: 'must be unique' }

    validates :hold, presence: true, inclusion: { in: Skyrim::HOLDS, message: 'must be one of the nine Skyrim holds, or Solstheim' }, uniqueness: { message: 'must be unique' }

    validates :city, inclusion: { in: VALID_CITIES, message: 'must be a Skyrim city in which an ownable property is located', allow_blank: true }, uniqueness: { message: 'must be unique if present', allow_blank: true }

    validates :add_on, inclusion: { in: SUPPORTED_ADD_ONS, message: UNSUPPORTED_ADD_ON_MESSAGE }

    def self.unique_identifier
      :name
    end

    private

    def ensure_max
      Rails.logger.error "Cannot create canonical property \"#{name}\" in hold \"#{hold}\": there are already #{TOTAL_PROPERTY_COUNT} canonical properties"
      errors.add(:base, "cannot create a new canonical property as there are already #{TOTAL_PROPERTY_COUNT}")
    end

    def count_is_max
      Property.count == TOTAL_PROPERTY_COUNT
    end
  end
end

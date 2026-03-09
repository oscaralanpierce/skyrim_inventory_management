# frozen_string_literal: true

module Canonical
  class PotionsAlchemicalProperty < ApplicationRecord
    self.table_name = 'canonical_potions_alchemical_properties'

    belongs_to :alchemical_property
    belongs_to :potion, class_name: 'Canonical::Potion'

    validates :alchemical_property_id, uniqueness: { scope: :potion_id, message: 'must form a unique combination with canonical potion' }
    validates :strength, numericality: { greater_than: 0, only_integer: true, allow_blank: true }
    validates :duration, numericality: { greater_than: 0, only_integer: true, allow_blank: true }

    validate :ensure_max_per_potion

    MAX_PER_POTION = 4

    private

    def ensure_max_per_potion
      return if potion.alchemical_properties.length < MAX_PER_POTION
      return if persisted? &&
        !potion_id_changed? &&
        potion.alchemical_properties.length == MAX_PER_POTION

      errors.add(:potion, "can have a maximum of #{MAX_PER_POTION} effects")
    end
  end
end

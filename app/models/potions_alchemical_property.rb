# frozen_string_literal: true

class PotionsAlchemicalProperty < ApplicationRecord
  belongs_to :potion
  belongs_to :alchemical_property

  validates :alchemical_property_id, uniqueness: { scope: :potion_id, message: 'must form a unique combination with potion' }
  validates :strength, numericality: { greater_than: 0, only_integer: true, allow_nil: true }
  validates :duration, numericality: { greater_than: 0, only_integer: true, allow_nil: true }
  validates :added_automatically, inclusion: { in: [true, false], message: 'must be true or false' }

  validate :ensure_max_per_potion

  before_validation :set_added_automatically, if: -> { added_automatically.nil? }
  after_save :update_canonical_potion

  scope :added_automatically, -> { where(added_automatically: true) }
  scope :added_manually, -> { where(added_automatically: false) }

  MAX_PER_POTION = Canonical::PotionsAlchemicalProperty::MAX_PER_POTION

  private

  def update_canonical_potion
    return if added_automatically == true

    potion.potions_alchemical_properties.reload
    potion.save!
  end

  def set_added_automatically
    self.added_automatically = false
  end

  def ensure_max_per_potion
    return if potion.alchemical_properties.length < MAX_PER_POTION
    return if persisted? &&
      !potion_id_changed? &&
      potion.alchemical_properties.length == MAX_PER_POTION

    errors.add(:potion, "can have a maximum of #{MAX_PER_POTION} effects")
  end
end

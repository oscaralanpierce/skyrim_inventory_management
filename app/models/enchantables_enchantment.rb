# frozen_string_literal: true

class EnchantablesEnchantment < ApplicationRecord
  belongs_to :enchantable, polymorphic: true
  belongs_to :enchantment

  validates :enchantment_id, uniqueness: { scope: %i[enchantable_id enchantable_type], message: 'must form a unique combination with enchantable item' }

  validates :added_automatically, inclusion: { in: [true, false], message: 'must be true or false' }

  before_validation :set_added_automatically

  after_validation :validate_against_canonical, if: :should_validate_against_canonical?

  after_save :update_canonical_enchantable, unless: :canonical_enchantable?

  scope :added_automatically, -> { where(added_automatically: true) }
  scope :added_manually, -> { where(added_automatically: false) }

  private

  def update_canonical_enchantable
    return if added_automatically == true

    enchantable.enchantables_enchantments.reload
    enchantable.save!
  end

  def validate_against_canonical
    errors.add(:base, "doesn't match any canonical model") unless valid_enchantable?
  end

  def valid_enchantable?
    enchantable.canonical_models.any? {|canonical| canonical.enchantable || canonical.enchantables_enchantments.where(enchantment:, strength:).any? }
  end

  def should_validate_against_canonical?
    errors.none? && !canonical_enchantable?
  end

  def set_added_automatically
    self.added_automatically = true if canonical_enchantable?
    self.added_automatically = false if added_automatically.nil?
  end

  def canonical_enchantable?
    enchantable_type.start_with?('Canonical::')
  end
end

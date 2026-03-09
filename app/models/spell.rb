# frozen_string_literal: true

require 'skyrim'

class Spell < ApplicationRecord
  has_many :canonical_staves_spells, dependent: :destroy, class_name: 'Canonical::StavesSpell', inverse_of: :spell
  has_many :staves, through: :canonical_staves_spells, class_name: 'Canonical::Staff'

  validates :name, presence: true, uniqueness: { message: 'must be unique' }
  validates :school, presence: true, inclusion: { in: Skyrim::MAGIC_SCHOOLS, message: 'must be a valid school of magic' }
  validates :level, presence: true, inclusion: { in: Skyrim::DIFFICULTY_LEVELS, message: 'must be "Novice", "Apprentice", "Adept", "Expert", or "Master"' }
  validates :strength_unit, inclusion: { in: %w[point percentage level], message: 'must be "point", "percentage", or the "level" of affected targets', allow_blank: true }
  validates :description, presence: true
  validates :add_on, presence: true, inclusion: { in: Canonical::SUPPORTED_ADD_ONS, message: Canonical::UNSUPPORTED_ADD_ON_MESSAGE }
  validate :strength_and_strength_unit_both_or_neither_present

  def self.unique_identifier
    :name
  end

  private

  def strength_and_strength_unit_both_or_neither_present
    if strength.present? && strength_unit.blank?
      errors.add(:strength_unit, 'must be present if strength is given')
    elsif strength_unit.present? && strength.blank?
      errors.add(:strength, 'must be present if strength unit is given')
    end
  end
end

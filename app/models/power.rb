# frozen_string_literal: true

class Power < ApplicationRecord
  has_many :canonical_powerables_powers, dependent: :destroy, class_name: 'Canonical::PowerablesPower'
  has_many :powerables, through: :canonical_powerables_powers

  validates :name, presence: true, uniqueness: { message: 'must be unique' }
  validates :power_type, presence: true, inclusion: { in: %w[greater lesser ability], message: 'must be "greater", "lesser", or "ability"' }
  validates :source, presence: true
  validates :description, presence: true
  validates :add_on, presence: true, inclusion: { in: Canonical::SUPPORTED_ADD_ONS, message: Canonical::UNSUPPORTED_ADD_ON_MESSAGE }

  def self.unique_identifier
    :name
  end
end

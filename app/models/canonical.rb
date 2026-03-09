# frozen_string_literal: true

module Canonical
  BOOLEAN_VALUES = [true, false].freeze
  BOOLEAN_VALIDATION_MESSAGE = 'must be true or false'

  SUPPORTED_ADD_ONS = %w[base dragonborn dawnguard hearthfire].freeze
  UNSUPPORTED_ADD_ON_MESSAGE = 'must be a SIM-supported add-on or DLC'

  def boolean?(value)
    BOOLEAN_VALUES.include?(value)
  end
end

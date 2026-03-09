# frozen_string_literal: true

class CreateCanonicalPowerablesPowers < ActiveRecord::Migration[6.1]
  def change
    create_table :canonical_powerables_powers do |t|
      t.references :power, null: false, foreign_key: true
      t.bigint :powerable_id, null: false
      t.string :powerable_type, null: false

      t.index %i[power_id powerable_id powerable_type], unique: true, name: 'index_powerables_powers_on_power_id_and_powerable'

      t.timestamps
    end
  end
end

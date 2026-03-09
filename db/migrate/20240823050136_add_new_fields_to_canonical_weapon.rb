# frozen_string_literal: true

class AddNewFieldsToCanonicalWeapon < ActiveRecord::Migration[7.2]
  def change
    add_column :canonical_weapons, :max_quantity, :integer
    add_column :canonical_weapons, :add_on, :string
    add_column :canonical_weapons, :collectible, :boolean
  end
end

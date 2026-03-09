# frozen_string_literal: true

class AddNewFieldsToCanonicalPotions < ActiveRecord::Migration[7.1]
  def change
    add_column :canonical_potions, :add_on, :string
    add_column :canonical_potions, :collectible, :boolean
    add_column :canonical_potions, :max_quantity, :integer
  end
end

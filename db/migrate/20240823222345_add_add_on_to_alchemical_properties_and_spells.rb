# frozen_string_literal: true

class AddAddOnToAlchemicalPropertiesAndSpells < ActiveRecord::Migration[7.2]
  def change
    add_column :alchemical_properties, :add_on, :string
    add_column :spells, :add_on, :string
  end
end

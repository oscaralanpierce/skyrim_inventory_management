# frozen_string_literal: true

class AddNewFieldsToCanonicalIngredient < ActiveRecord::Migration[7.1]
  def change
    add_column :canonical_ingredients, :add_on, :string
    add_column :canonical_ingredients, :max_quantity, :integer
    add_column :canonical_ingredients, :collectible, :boolean
  end
end

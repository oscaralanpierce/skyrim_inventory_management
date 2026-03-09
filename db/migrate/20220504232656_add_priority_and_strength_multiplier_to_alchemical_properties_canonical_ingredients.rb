# frozen_string_literal: true

class AddPriorityAndStrengthMultiplierToAlchemicalPropertiesCanonicalIngredients < ActiveRecord::Migration[6.1]
  def change
    add_column :canonical_ingredients_alchemical_properties, :priority, :integer, null: false
    add_column :canonical_ingredients_alchemical_properties, :strength_modifier, :decimal
    add_column :canonical_ingredients_alchemical_properties, :duration_modifier, :decimal
    add_index :canonical_ingredients_alchemical_properties, %i[priority ingredient_id], unique: true, name: :index_can_ingrs_alc_props_on_priority_and_ingr_id
  end
end

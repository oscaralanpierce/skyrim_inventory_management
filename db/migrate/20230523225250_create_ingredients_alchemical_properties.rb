# frozen_string_literal: true

class CreateIngredientsAlchemicalProperties < ActiveRecord::Migration[7.0]
  def change
    create_table :ingredients_alchemical_properties do |t|
      t.references :ingredient, null: false, foreign_key: true
      t.references :alchemical_property, null: false, foreign_key: true, index: { name: 'index_ingredients_alc_properties_on_alc_property_id' }

      t.integer :priority
      t.decimal :strength_modifier
      t.decimal :duration_modifier

      t.index %i[alchemical_property_id ingredient_id], unique: true, name: 'index_ingredients_alc_properties_on_property_and_ingr_ids'
      t.index %i[priority ingredient_id], unique: true, name: 'index_ingrs_alc_props_on_priority_and_ingr_id'

      t.timestamps
    end
  end
end

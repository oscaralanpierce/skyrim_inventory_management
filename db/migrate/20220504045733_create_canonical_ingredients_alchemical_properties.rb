# frozen_string_literal: true

class CreateCanonicalIngredientsAlchemicalProperties < ActiveRecord::Migration[6.1]
  def change
    create_table :canonical_ingredients_alchemical_properties do |t|
      t.references :alchemical_property, null: false, foreign_key: true, index: { name: 'index_can_ingredients_alc_properties_on_alc_property_id' }
      t.references :ingredient, null: false, foreign_key: { to_table: 'canonical_ingredients' }, index: { name: 'index_can_ingredients_alc_properties_on_can_ingredient_id' }

      t.index %i[alchemical_property_id ingredient_id], unique: true, name: 'index_can_ingredients_alc_properties_on_property_and_ingr_ids'

      t.timestamps
    end
  end
end

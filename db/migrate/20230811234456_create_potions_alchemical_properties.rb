# frozen_string_literal: true

class CreatePotionsAlchemicalProperties < ActiveRecord::Migration[7.0]
  def change
    create_table :potions_alchemical_properties do |t|
      t.references :potion, null: false, foreign_key: true
      t.references :alchemical_property, null: false, foreign_key: true
      t.integer :strength
      t.integer :duration

      t.index %i[potion_id alchemical_property_id], unique: true, name: 'index_potions_alc_properties_on_potion_id_alc_property_id'

      t.timestamps
    end
  end
end

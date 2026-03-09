# frozen_string_literal: true

class CreateCanonicalPotionsAlchemicalProperties < ActiveRecord::Migration[6.1]
  def change
    create_table :canonical_potions_alchemical_properties do |t|
      t.references :potion, null: false, foreign_key: { to_table: 'canonical_potions' }
      t.references :alchemical_property, null: false, foreign_key: true, index: { name: 'index_can_potions_properties_on_alc_property_id' }
      t.integer :strength
      t.integer :duration

      t.index %i[potion_id alchemical_property_id], unique: true, name: 'index_can_potions_properties_on_potion_and_property'

      t.timestamps
    end
  end
end

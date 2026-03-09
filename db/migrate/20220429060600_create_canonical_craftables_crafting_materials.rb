# frozen_string_literal: true

class CreateCanonicalCraftablesCraftingMaterials < ActiveRecord::Migration[6.1]
  def change
    create_table :canonical_craftables_crafting_materials do |t|
      t.references :material, null: false, foreign_key: { to_table: 'canonical_materials' }, index: { name: :index_canonical_armors_smithing_mats_on_canonical_mat_id }
      t.bigint :craftable_id, null: false
      t.string :craftable_type, null: false
      t.integer :quantity, default: 1, null: false

      t.index %i[material_id craftable_id craftable_type], unique: true, name: 'index_can_craftables_crafting_materials_on_mat_id_and_craftable'

      t.timestamps
    end
  end
end

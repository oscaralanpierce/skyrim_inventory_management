# frozen_string_literal: true

class CreateCanonicalTemperablesTemperingMaterials < ActiveRecord::Migration[6.1]
  def change
    create_table :canonical_temperables_tempering_materials do |t|
      t.references :material, null: false, foreign_key: { to_table: 'canonical_materials' }, index: { name: :index_canonical_armors_tempering_mats_on_canonical_material_id }
      t.bigint :temperable_id, null: false
      t.string :temperable_type, null: false
      t.integer :quantity, default: 1, null: false

      t.index %i[material_id temperable_id temperable_type], unique: true, name: 'index_temperables_tempering_mats_on_mat_id_and_temperable'

      t.timestamps
    end
  end
end

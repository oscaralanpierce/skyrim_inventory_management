# frozen_string_literal: true

class AddAddOnToCanonicalRawMaterials < ActiveRecord::Migration[7.2]
  def change
    add_column :canonical_raw_materials, :add_on, :string
  end
end

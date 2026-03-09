# frozen_string_literal: true

class AddNewAttributesToCanonicalJewelryItem < ActiveRecord::Migration[7.1]
  def change
    add_column :canonical_jewelry_items, :add_on, :string
    add_column :canonical_jewelry_items, :max_quantity, :integer
    add_column :canonical_jewelry_items, :collectible, :boolean
  end
end

# frozen_string_literal: true

class AddNewFieldsToCanonicalClothingItems < ActiveRecord::Migration[7.1]
  def change
    add_column :canonical_clothing_items, :add_on, :string
    add_column :canonical_clothing_items, :max_quantity, :integer
    add_column :canonical_clothing_items, :collectible, :boolean
  end
end

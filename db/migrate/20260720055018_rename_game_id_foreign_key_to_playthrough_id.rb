# frozen_string_literal: true

class RenameGameIdForeignKeyToPlaythroughId < ActiveRecord::Migration[8.1]
  def change
    rename_column :armors, :playthrough_id, :playthrough_id
    rename_column :books, :playthrough_id, :playthrough_id
    rename_column :clothing_items, :playthrough_id, :playthrough_id
    rename_column :ingredients, :playthrough_id, :playthrough_id
    rename_column :inventory_lists, :playthrough_id, :playthrough_id
    rename_column :jewelry_items, :playthrough_id, :playthrough_id
    rename_column :misc_items, :playthrough_id, :playthrough_id
    rename_column :potions, :playthrough_id, :playthrough_id
    rename_column :properties, :playthrough_id, :playthrough_id
    rename_column :staves, :playthrough_id, :playthrough_id
    rename_column :weapons, :playthrough_id, :playthrough_id
    rename_column :wish_lists, :playthrough_id, :playthrough_id
  end
end

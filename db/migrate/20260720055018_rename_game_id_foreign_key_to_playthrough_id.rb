# frozen_string_literal: true

class RenameGameIdForeignKeyToPlaythroughId < ActiveRecord::Migration[8.1]
  def change
    rename_column :armors, :game_id, :playthrough_id
    rename_column :books, :game_id, :playthrough_id
    rename_column :clothing_items, :game_id, :playthrough_id
    rename_column :ingredients, :game_id, :playthrough_id
    rename_column :inventory_lists, :game_id, :playthrough_id
    rename_column :jewelry_items, :game_id, :playthrough_id
    rename_column :misc_items, :game_id, :playthrough_id
    rename_column :potions, :game_id, :playthrough_id
    rename_column :properties, :game_id, :playthrough_id
    rename_column :staves, :game_id, :playthrough_id
    rename_column :weapons, :game_id, :playthrough_id
    rename_column :wish_lists, :game_id, :playthrough_id
  end
end

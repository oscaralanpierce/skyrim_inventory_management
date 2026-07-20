# frozen_string_literal: true

class RenameGamesToPlaythroughs < ActiveRecord::Migration[8.1]
  def change
    rename_table :games, :playthroughs
  end
end

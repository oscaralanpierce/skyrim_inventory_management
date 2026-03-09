# frozen_string_literal: true

class AddNewFieldsToCanonicalMiscItem < ActiveRecord::Migration[7.1]
  def change
    add_column :canonical_misc_items, :add_on, :string
    add_column :canonical_misc_items, :max_quantity, :integer
    add_column :canonical_misc_items, :collectible, :boolean
  end
end

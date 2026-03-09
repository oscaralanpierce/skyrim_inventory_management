# frozen_string_literal: true

class AddNewFieldsToCanonicalBooks < ActiveRecord::Migration[7.1]
  def change
    add_column :canonical_books, :add_on, :string
    add_column :canonical_books, :max_quantity, :integer
    add_column :canonical_books, :collectible, :boolean
  end
end

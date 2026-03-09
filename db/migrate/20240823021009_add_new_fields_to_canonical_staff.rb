# frozen_string_literal: true

class AddNewFieldsToCanonicalStaff < ActiveRecord::Migration[7.2]
  def change
    add_column :canonical_staves, :max_quantity, :integer
    add_column :canonical_staves, :add_on, :string
    add_column :canonical_staves, :collectible, :boolean
  end
end

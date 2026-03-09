# frozen_string_literal: true

class AddAddOnToCanonicalProperties < ActiveRecord::Migration[7.1]
  def change
    add_column :canonical_properties, :add_on, :string
  end
end

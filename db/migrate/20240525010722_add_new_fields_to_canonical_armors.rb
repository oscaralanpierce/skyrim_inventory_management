# frozen_string_literal: true

class AddNewFieldsToCanonicalArmors < ActiveRecord::Migration[7.1]
  def change
    add_column :canonical_armors, :add_on, :string
    add_column :canonical_armors, :max_quantity, :integer
    add_column :canonical_armors, :collectible, :boolean
  end
end

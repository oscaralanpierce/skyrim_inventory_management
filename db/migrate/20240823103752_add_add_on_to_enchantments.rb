# frozen_string_literal: true

class AddAddOnToEnchantments < ActiveRecord::Migration[7.2]
  def change
    add_column :enchantments, :add_on, :string
  end
end

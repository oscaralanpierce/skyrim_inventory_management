# frozen_string_literal: true

class AddAddedAutomaticallyToJoinModels < ActiveRecord::Migration[7.1]
  def up
    add_column :enchantables_enchantments, :added_automatically, :boolean, default: false

    add_column :potions_alchemical_properties, :added_automatically, :boolean, default: false

    # rubocop:disable Rails/SkipsModelValidations
    EnchantablesEnchantment.update_all(added_automatically: true)
    PotionsAlchemicalProperty.update_all(added_automatically: true)
    # rubocop:enable Rails/SkipsModelValidations

    change_column_null :enchantables_enchantments, :added_automatically, false
    change_column_null :potions_alchemical_properties, :added_automatically, false
  end

  def down
    remove_column :enchantables_enchantments, :added_automatically
    remove_column :potions_alchemical_properties, :added_automatically
  end
end

# frozen_string_literal: true

module Canonical
  module Sync
    class PrerequisiteNotMetError < StandardError; end
    class DataIntegrityError < StandardError; end

    SYNCERS = {
      # Syncers that are prerequisites for other syncers
      alchemical_property: Canonical::Sync::AlchemicalProperties,
      enchantment: Canonical::Sync::Enchantments,
      raw_material: Canonical::Sync::RawMaterials,
      power: Canonical::Sync::Powers,
      spell: Canonical::Sync::Spells,
      ingredient: Canonical::Sync::Ingredients,
      weapon: Canonical::Sync::Weapons,
      armor: Canonical::Sync::Armor,
      jewelry: Canonical::Sync::JewelryItems,
      # Syncers that are not prerequisites for other syncers
      book: Canonical::Sync::Books,
      clothing: Canonical::Sync::ClothingItems,
      misc_item: Canonical::Sync::MiscItems,
      potion: Canonical::Sync::Potions,
      property: Canonical::Sync::Properties,
      staff: Canonical::Sync::Staves,
      crafting_material: Canonical::Sync::CraftingMaterials,
      tempering_material: Canonical::Sync::TemperingMaterials,
    }.freeze

    module_function

    def perform(model: :all, preserve_existing_records: false)
      if model == :all
        SYNCERS.each_value {|syncer| syncer.perform(preserve_existing_records:) }
      else
        SYNCERS[model].perform(preserve_existing_records:)
      end
    end
  end
end

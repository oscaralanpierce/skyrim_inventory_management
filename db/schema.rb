# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_07_20_055018) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "alchemical_properties", force: :cascade do |t|
    t.string "add_on", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "effect_type", null: false
    t.boolean "effects_cumulative", default: false
    t.string "name", null: false
    t.string "strength_unit"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_alchemical_properties_on_name", unique: true
  end

  create_table "armors", force: :cascade do |t|
    t.bigint "canonical_armor_id"
    t.datetime "created_at", null: false
    t.string "magical_effects"
    t.string "name", null: false
    t.bigint "playthrough_id", null: false
    t.decimal "unit_weight", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.string "weight"
    t.index ["canonical_armor_id"], name: "index_armors_on_canonical_armor_id"
    t.index ["playthrough_id"], name: "index_armors_on_playthrough_id"
  end

  create_table "books", force: :cascade do |t|
    t.string "authors", default: [], array: true
    t.bigint "canonical_book_id"
    t.datetime "created_at", null: false
    t.bigint "playthrough_id", null: false
    t.string "skill_name"
    t.string "title", null: false
    t.decimal "unit_weight", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.index ["canonical_book_id"], name: "index_books_on_canonical_book_id"
    t.index ["playthrough_id"], name: "index_books_on_playthrough_id"
  end

  create_table "canonical_armors", force: :cascade do |t|
    t.string "add_on", null: false
    t.string "body_slot", null: false
    t.boolean "collectible", null: false
    t.datetime "created_at", null: false
    t.boolean "dragon_priest_mask", default: false
    t.boolean "enchantable", default: true
    t.string "item_code", null: false
    t.boolean "leveled", default: false
    t.string "magical_effects"
    t.integer "max_quantity"
    t.string "name", null: false
    t.boolean "purchasable", null: false
    t.boolean "quest_item", default: false, null: false
    t.boolean "quest_reward", default: false
    t.boolean "rare_item", null: false
    t.string "smithing_perks", default: [], array: true
    t.boolean "unique_item", default: false, null: false
    t.decimal "unit_weight", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.string "weight", null: false
    t.index ["item_code"], name: "index_canonical_armors_on_item_code", unique: true
  end

  create_table "canonical_books", force: :cascade do |t|
    t.string "add_on", null: false
    t.string "authors", default: [], array: true
    t.string "book_type", null: false
    t.boolean "collectible", null: false
    t.datetime "created_at", null: false
    t.string "item_code", null: false
    t.integer "max_quantity"
    t.boolean "purchasable", null: false
    t.boolean "quest_item", default: false, null: false
    t.boolean "quest_reward", default: false
    t.boolean "rare_item", default: false, null: false
    t.string "skill_name"
    t.boolean "solstheim_only", default: false, null: false
    t.string "title", null: false
    t.string "title_variants", default: [], array: true
    t.boolean "unique_item", default: false, null: false
    t.decimal "unit_weight", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["item_code"], name: "index_canonical_books_on_item_code", unique: true
  end

  create_table "canonical_clothing_items", force: :cascade do |t|
    t.string "add_on", null: false
    t.string "body_slot", null: false
    t.boolean "collectible", null: false
    t.datetime "created_at", null: false
    t.boolean "enchantable", default: true, null: false
    t.string "item_code", null: false
    t.string "magical_effects"
    t.integer "max_quantity"
    t.string "name", null: false
    t.boolean "purchasable", null: false
    t.boolean "quest_item", default: false, null: false
    t.boolean "quest_reward", default: false
    t.boolean "rare_item", null: false
    t.boolean "unique_item", default: false, null: false
    t.decimal "unit_weight", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["item_code"], name: "index_canonical_clothing_items_on_item_code", unique: true
  end

  create_table "canonical_ingredients", force: :cascade do |t|
    t.string "add_on", null: false
    t.boolean "collectible", null: false
    t.datetime "created_at", null: false
    t.string "ingredient_type"
    t.string "item_code", null: false
    t.integer "max_quantity"
    t.string "name", null: false
    t.boolean "purchasable", null: false
    t.boolean "purchase_requires_perk"
    t.boolean "quest_item", default: false, null: false
    t.boolean "rare_item", null: false
    t.boolean "unique_item", default: false, null: false
    t.decimal "unit_weight", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["item_code"], name: "index_canonical_ingredients_on_item_code", unique: true
  end

  create_table "canonical_ingredients_alchemical_properties", force: :cascade do |t|
    t.bigint "alchemical_property_id", null: false
    t.datetime "created_at", null: false
    t.decimal "duration_modifier"
    t.bigint "ingredient_id", null: false
    t.integer "priority", null: false
    t.decimal "strength_modifier"
    t.datetime "updated_at", null: false
    t.index ["alchemical_property_id", "ingredient_id"], name: "index_can_ingredients_alc_properties_on_property_and_ingr_ids", unique: true
    t.index ["alchemical_property_id"], name: "index_can_ingredients_alc_properties_on_alc_property_id"
    t.index ["ingredient_id"], name: "index_can_ingredients_alc_properties_on_can_ingredient_id"
    t.index ["priority", "ingredient_id"], name: "index_can_ingrs_alc_props_on_priority_and_ingr_id", unique: true
  end

  create_table "canonical_jewelry_items", force: :cascade do |t|
    t.string "add_on", null: false
    t.boolean "collectible", null: false
    t.datetime "created_at", null: false
    t.boolean "enchantable", default: true, null: false
    t.string "item_code", null: false
    t.string "jewelry_type", null: false
    t.string "magical_effects"
    t.integer "max_quantity"
    t.string "name", null: false
    t.boolean "purchasable", null: false
    t.boolean "quest_item", default: false, null: false
    t.boolean "quest_reward", default: false
    t.boolean "rare_item", null: false
    t.boolean "unique_item", default: false, null: false
    t.decimal "unit_weight", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["item_code"], name: "index_canonical_jewelry_items_on_item_code", unique: true
  end

  create_table "canonical_materials", force: :cascade do |t|
    t.bigint "craftable_id"
    t.string "craftable_type"
    t.datetime "created_at", null: false
    t.integer "quantity", null: false
    t.bigint "source_material_id", null: false
    t.string "source_material_type", null: false
    t.bigint "temperable_id"
    t.string "temperable_type"
    t.datetime "updated_at", null: false
    t.index ["craftable_type", "craftable_id"], name: "index_canonical_materials_on_craftable"
    t.index ["source_material_type", "source_material_id"], name: "index_canonical_materials_on_source_material"
    t.index ["temperable_type", "temperable_id"], name: "index_canonical_materials_on_temperable"
  end

  create_table "canonical_misc_items", force: :cascade do |t|
    t.string "add_on", null: false
    t.boolean "collectible", null: false
    t.datetime "created_at", null: false
    t.string "description"
    t.string "item_code", null: false
    t.string "item_types", default: [], null: false, array: true
    t.integer "max_quantity"
    t.string "name", null: false
    t.boolean "purchasable", null: false
    t.boolean "quest_item", default: false, null: false
    t.boolean "quest_reward", default: false
    t.boolean "rare_item", null: false
    t.boolean "unique_item", null: false
    t.decimal "unit_weight", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["item_code"], name: "index_canonical_misc_items_on_item_code", unique: true
  end

  create_table "canonical_potions", force: :cascade do |t|
    t.string "add_on", null: false
    t.boolean "collectible", null: false
    t.datetime "created_at", null: false
    t.string "item_code", null: false
    t.string "magical_effects"
    t.integer "max_quantity"
    t.string "name", null: false
    t.boolean "purchasable", default: true, null: false
    t.boolean "quest_item", default: false, null: false
    t.boolean "quest_reward", default: false
    t.boolean "rare_item", default: false, null: false
    t.boolean "unique_item", default: false, null: false
    t.decimal "unit_weight", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["item_code"], name: "index_canonical_potions_on_item_code", unique: true
  end

  create_table "canonical_potions_alchemical_properties", force: :cascade do |t|
    t.bigint "alchemical_property_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration"
    t.bigint "potion_id", null: false
    t.integer "strength"
    t.datetime "updated_at", null: false
    t.index ["alchemical_property_id"], name: "index_can_potions_properties_on_alc_property_id"
    t.index ["potion_id", "alchemical_property_id"], name: "index_can_potions_properties_on_potion_and_property", unique: true
    t.index ["potion_id"], name: "index_canonical_potions_alchemical_properties_on_potion_id"
  end

  create_table "canonical_powerables_powers", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "power_id", null: false
    t.bigint "powerable_id", null: false
    t.string "powerable_type", null: false
    t.datetime "updated_at", null: false
    t.index ["power_id", "powerable_id", "powerable_type"], name: "index_powerables_powers_on_power_id_and_powerable", unique: true
    t.index ["power_id"], name: "index_canonical_powerables_powers_on_power_id"
  end

  create_table "canonical_properties", force: :cascade do |t|
    t.string "add_on", null: false
    t.boolean "alchemy_lab_available", default: true
    t.boolean "alchemy_tower_available", default: false
    t.boolean "apiary_available", default: false
    t.boolean "arcane_enchanter_available", default: false
    t.boolean "armory_available", default: false
    t.boolean "bedrooms_available", default: false
    t.boolean "cellar_available", default: false
    t.string "city"
    t.datetime "created_at", null: false
    t.boolean "enchanters_tower_available", default: false
    t.boolean "fish_hatchery_available", default: false
    t.boolean "forge_available", default: false
    t.boolean "grain_mill_available", default: false
    t.boolean "greenhouse_available", default: false
    t.string "hold", null: false
    t.boolean "kitchen_available", default: false
    t.boolean "library_available", default: false
    t.boolean "main_hall_available"
    t.string "name", null: false
    t.boolean "storage_room_available", default: false
    t.boolean "trophy_room_available", default: false
    t.datetime "updated_at", null: false
    t.index ["city"], name: "index_canonical_properties_on_city", unique: true
    t.index ["hold"], name: "index_canonical_properties_on_hold", unique: true
    t.index ["name"], name: "index_canonical_properties_on_name", unique: true
  end

  create_table "canonical_raw_materials", force: :cascade do |t|
    t.string "add_on", null: false
    t.boolean "building_material", default: false
    t.datetime "created_at", null: false
    t.string "item_code", null: false
    t.string "name", null: false
    t.boolean "smithing_material", default: false
    t.decimal "unit_weight", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["item_code"], name: "index_canonical_raw_materials_on_item_code", unique: true
  end

  create_table "canonical_staves", force: :cascade do |t|
    t.string "add_on", null: false
    t.integer "base_damage", null: false
    t.boolean "collectible", null: false
    t.datetime "created_at", null: false
    t.boolean "daedric", default: false, null: false
    t.string "enemy"
    t.string "item_code", null: false
    t.boolean "leveled", default: false, null: false
    t.string "magical_effects"
    t.integer "max_quantity"
    t.string "name", null: false
    t.boolean "purchasable", null: false
    t.boolean "quest_item", default: false, null: false
    t.boolean "quest_reward", default: false
    t.boolean "rare_item", null: false
    t.string "school"
    t.boolean "unique_item", default: false, null: false
    t.decimal "unit_weight", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.index ["item_code"], name: "index_canonical_staves_on_item_code", unique: true
  end

  create_table "canonical_staves_spells", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "spell_id", null: false
    t.bigint "staff_id", null: false
    t.integer "strength"
    t.datetime "updated_at", null: false
    t.index ["spell_id", "staff_id"], name: "index_canonical_staves_spells_on_spell_id_and_staff_id", unique: true
    t.index ["spell_id"], name: "index_canonical_staves_spells_on_spell_id"
    t.index ["staff_id"], name: "index_canonical_staves_spells_on_staff_id"
  end

  create_table "canonical_weapons", force: :cascade do |t|
    t.string "add_on", null: false
    t.integer "base_damage", null: false
    t.string "category", null: false
    t.boolean "collectible", null: false
    t.datetime "created_at", null: false
    t.boolean "enchantable", default: true
    t.string "item_code", null: false
    t.boolean "leveled", default: false
    t.string "magical_effects"
    t.integer "max_quantity"
    t.string "name", null: false
    t.boolean "purchasable", null: false
    t.boolean "quest_item", default: false, null: false
    t.boolean "quest_reward", default: false
    t.boolean "rare_item", null: false
    t.string "smithing_perks", default: [], array: true
    t.boolean "unique_item", default: false, null: false
    t.decimal "unit_weight", precision: 5, scale: 2, null: false
    t.datetime "updated_at", null: false
    t.string "weapon_type", null: false
    t.index ["item_code"], name: "index_canonical_weapons_on_item_code", unique: true
  end

  create_table "clothing_items", force: :cascade do |t|
    t.bigint "canonical_clothing_item_id"
    t.datetime "created_at", null: false
    t.string "magical_effects"
    t.string "name", null: false
    t.bigint "playthrough_id", null: false
    t.decimal "unit_weight", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.index ["canonical_clothing_item_id"], name: "index_clothing_items_on_canonical_clothing_item_id"
    t.index ["playthrough_id"], name: "index_clothing_items_on_playthrough_id"
  end

  create_table "enchantables_enchantments", force: :cascade do |t|
    t.boolean "added_automatically", default: false, null: false
    t.datetime "created_at", null: false
    t.bigint "enchantable_id", null: false
    t.string "enchantable_type", null: false
    t.bigint "enchantment_id", null: false
    t.decimal "strength", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.index ["enchantment_id", "enchantable_id", "enchantable_type"], name: "index_enchantables_enchantments_on_enchmnt_id_enchble_id_type", unique: true
    t.index ["enchantment_id"], name: "index_enchantables_enchantments_on_enchantment_id"
  end

  create_table "enchantments", force: :cascade do |t|
    t.string "add_on", null: false
    t.datetime "created_at", null: false
    t.string "enchantable_items", default: [], array: true
    t.string "name", null: false
    t.string "school"
    t.string "strength_unit"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_enchantments_on_name", unique: true
  end

  create_table "ingredients", force: :cascade do |t|
    t.bigint "canonical_ingredient_id"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "playthrough_id", null: false
    t.decimal "unit_weight", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.index ["canonical_ingredient_id"], name: "index_ingredients_on_canonical_ingredient_id"
    t.index ["playthrough_id"], name: "index_ingredients_on_playthrough_id"
  end

  create_table "ingredients_alchemical_properties", force: :cascade do |t|
    t.bigint "alchemical_property_id", null: false
    t.datetime "created_at", null: false
    t.bigint "ingredient_id", null: false
    t.integer "priority"
    t.datetime "updated_at", null: false
    t.index ["alchemical_property_id", "ingredient_id"], name: "index_ingredients_alc_properties_on_property_and_ingr_ids", unique: true
    t.index ["alchemical_property_id"], name: "index_ingredients_alc_properties_on_alc_property_id"
    t.index ["ingredient_id"], name: "index_ingredients_alchemical_properties_on_ingredient_id"
    t.index ["priority", "ingredient_id"], name: "index_ingrs_alc_props_on_priority_and_ingr_id", unique: true
  end

  create_table "inventory_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.bigint "list_id", null: false
    t.string "notes"
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_weight", precision: 5, scale: 1
    t.datetime "updated_at", null: false
    t.index ["description", "list_id"], name: "index_inventory_items_on_description_and_list_id", unique: true
    t.index ["list_id"], name: "index_inventory_items_on_list_id"
  end

  create_table "inventory_lists", force: :cascade do |t|
    t.boolean "aggregate", default: false, null: false
    t.bigint "aggregate_list_id"
    t.datetime "created_at", null: false
    t.bigint "playthrough_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["aggregate_list_id"], name: "index_inventory_lists_on_aggregate_list_id"
    t.index ["playthrough_id"], name: "index_inventory_lists_on_playthrough_id"
    t.index ["title", "playthrough_id"], name: "index_inventory_lists_on_title_and_playthrough_id", unique: true
  end

  create_table "jewelry_items", force: :cascade do |t|
    t.bigint "canonical_jewelry_item_id"
    t.datetime "created_at", null: false
    t.string "magical_effects"
    t.string "name", null: false
    t.bigint "playthrough_id", null: false
    t.decimal "unit_weight", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.index ["canonical_jewelry_item_id"], name: "index_jewelry_items_on_canonical_jewelry_item_id"
    t.index ["playthrough_id"], name: "index_jewelry_items_on_playthrough_id"
  end

  create_table "misc_items", force: :cascade do |t|
    t.bigint "canonical_misc_item_id"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "playthrough_id", null: false
    t.decimal "unit_weight", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.index ["canonical_misc_item_id"], name: "index_misc_items_on_canonical_misc_item_id"
    t.index ["playthrough_id"], name: "index_misc_items_on_playthrough_id"
  end

  create_table "playthroughs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["name", "user_id"], name: "index_playthroughs_on_name_and_user_id", unique: true
    t.index ["user_id"], name: "index_playthroughs_on_user_id"
  end

  create_table "potions", force: :cascade do |t|
    t.bigint "canonical_potion_id"
    t.datetime "created_at", null: false
    t.string "magical_effects"
    t.string "name", null: false
    t.bigint "playthrough_id", null: false
    t.decimal "unit_weight", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.index ["canonical_potion_id"], name: "index_potions_on_canonical_potion_id"
    t.index ["playthrough_id"], name: "index_potions_on_playthrough_id"
  end

  create_table "potions_alchemical_properties", force: :cascade do |t|
    t.boolean "added_automatically", default: false, null: false
    t.bigint "alchemical_property_id", null: false
    t.datetime "created_at", null: false
    t.integer "duration"
    t.bigint "potion_id", null: false
    t.integer "strength"
    t.datetime "updated_at", null: false
    t.index ["alchemical_property_id"], name: "index_potions_alchemical_properties_on_alchemical_property_id"
    t.index ["potion_id", "alchemical_property_id"], name: "index_potions_alc_properties_on_potion_id_alc_property_id", unique: true
    t.index ["potion_id"], name: "index_potions_alchemical_properties_on_potion_id"
  end

  create_table "powers", force: :cascade do |t|
    t.string "add_on", null: false
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.string "name", null: false
    t.string "power_type", null: false
    t.string "source", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_powers_on_name", unique: true
  end

  create_table "properties", force: :cascade do |t|
    t.bigint "canonical_property_id", null: false
    t.string "city"
    t.datetime "created_at", null: false
    t.boolean "has_alchemy_lab", default: false
    t.boolean "has_alchemy_tower"
    t.boolean "has_apiary"
    t.boolean "has_arcane_enchanter", default: false
    t.boolean "has_armory"
    t.boolean "has_bedrooms"
    t.boolean "has_cellar"
    t.boolean "has_enchanters_tower"
    t.boolean "has_fish_hatchery"
    t.boolean "has_forge", default: false
    t.boolean "has_grain_mill"
    t.boolean "has_greenhouse"
    t.boolean "has_kitchen"
    t.boolean "has_library"
    t.boolean "has_main_hall"
    t.boolean "has_storage_room"
    t.boolean "has_trophy_room"
    t.string "hold", null: false
    t.string "name", null: false
    t.bigint "playthrough_id", null: false
    t.datetime "updated_at", null: false
    t.index ["canonical_property_id"], name: "index_properties_on_canonical_property_id"
    t.index ["playthrough_id", "canonical_property_id"], name: "index_properties_on_playthrough_id_and_canonical_property_id", unique: true
    t.index ["playthrough_id", "city"], name: "index_properties_on_playthrough_id_and_city", unique: true
    t.index ["playthrough_id", "hold"], name: "index_properties_on_playthrough_id_and_hold", unique: true
    t.index ["playthrough_id", "name"], name: "index_properties_on_playthrough_id_and_name", unique: true
    t.index ["playthrough_id"], name: "index_properties_on_playthrough_id"
  end

  create_table "recipes_canonical_ingredients", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "ingredient_id", null: false
    t.bigint "recipe_id", null: false
    t.string "recipe_type", null: false
    t.datetime "updated_at", null: false
    t.index ["ingredient_id"], name: "index_recipes_canonical_ingredients_on_ingredient_id"
    t.index ["recipe_id", "recipe_type", "ingredient_id"], name: "index_recipes_can_ingredients_on_recipe_and_ingredient", unique: true
    t.index ["recipe_id"], name: "index_recipes_canonical_ingredients_on_recipe_id"
  end

  create_table "spells", force: :cascade do |t|
    t.string "add_on", null: false
    t.integer "base_duration"
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.boolean "effects_cumulative", default: false
    t.string "level", null: false
    t.string "name", null: false
    t.string "school", null: false
    t.integer "strength"
    t.string "strength_unit"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_spells_on_name", unique: true
  end

  create_table "staves", force: :cascade do |t|
    t.bigint "canonical_staff_id"
    t.datetime "created_at", null: false
    t.string "magical_effects"
    t.string "name", null: false
    t.bigint "playthrough_id", null: false
    t.decimal "unit_weight", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.index ["canonical_staff_id"], name: "index_staves_on_canonical_staff_id"
    t.index ["playthrough_id"], name: "index_staves_on_playthrough_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "display_name"
    t.string "email", null: false
    t.string "photo_url"
    t.string "uid", null: false
    t.datetime "updated_at", null: false
    t.index ["uid"], name: "index_users_on_uid", unique: true
  end

  create_table "weapons", force: :cascade do |t|
    t.bigint "canonical_weapon_id"
    t.string "category"
    t.datetime "created_at", null: false
    t.string "magical_effects"
    t.string "name", null: false
    t.bigint "playthrough_id", null: false
    t.decimal "unit_weight", precision: 5, scale: 2
    t.datetime "updated_at", null: false
    t.string "weapon_type"
    t.index ["canonical_weapon_id"], name: "index_weapons_on_canonical_weapon_id"
    t.index ["playthrough_id"], name: "index_weapons_on_playthrough_id"
  end

  create_table "wish_list_items", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "description", null: false
    t.bigint "list_id", null: false
    t.string "notes"
    t.integer "quantity", default: 1, null: false
    t.decimal "unit_weight", precision: 5, scale: 1
    t.datetime "updated_at", null: false
    t.index ["description", "list_id"], name: "index_wish_list_items_on_description_and_list_id", unique: true
    t.index ["list_id"], name: "index_wish_list_items_on_list_id"
  end

  create_table "wish_lists", force: :cascade do |t|
    t.boolean "aggregate", default: false
    t.bigint "aggregate_list_id"
    t.datetime "created_at", null: false
    t.bigint "playthrough_id", null: false
    t.string "title", null: false
    t.datetime "updated_at", null: false
    t.index ["aggregate_list_id"], name: "index_wish_lists_on_aggregate_list_id"
    t.index ["playthrough_id"], name: "index_wish_lists_on_playthrough_id"
    t.index ["title", "playthrough_id"], name: "index_wish_lists_on_title_and_playthrough_id", unique: true
  end

  add_foreign_key "armors", "canonical_armors"
  add_foreign_key "armors", "playthroughs"
  add_foreign_key "books", "canonical_books"
  add_foreign_key "books", "playthroughs"
  add_foreign_key "canonical_ingredients_alchemical_properties", "alchemical_properties"
  add_foreign_key "canonical_ingredients_alchemical_properties", "canonical_ingredients", column: "ingredient_id"
  add_foreign_key "canonical_potions_alchemical_properties", "alchemical_properties"
  add_foreign_key "canonical_potions_alchemical_properties", "canonical_potions", column: "potion_id"
  add_foreign_key "canonical_powerables_powers", "powers"
  add_foreign_key "canonical_staves_spells", "canonical_staves", column: "staff_id"
  add_foreign_key "canonical_staves_spells", "spells"
  add_foreign_key "clothing_items", "canonical_clothing_items"
  add_foreign_key "clothing_items", "playthroughs"
  add_foreign_key "enchantables_enchantments", "enchantments"
  add_foreign_key "ingredients", "canonical_ingredients"
  add_foreign_key "ingredients", "playthroughs"
  add_foreign_key "ingredients_alchemical_properties", "alchemical_properties"
  add_foreign_key "ingredients_alchemical_properties", "ingredients"
  add_foreign_key "inventory_items", "inventory_lists", column: "list_id"
  add_foreign_key "inventory_lists", "inventory_lists", column: "aggregate_list_id"
  add_foreign_key "inventory_lists", "playthroughs"
  add_foreign_key "jewelry_items", "canonical_jewelry_items"
  add_foreign_key "jewelry_items", "playthroughs"
  add_foreign_key "misc_items", "canonical_misc_items"
  add_foreign_key "misc_items", "playthroughs"
  add_foreign_key "playthroughs", "users"
  add_foreign_key "potions", "canonical_potions"
  add_foreign_key "potions", "playthroughs"
  add_foreign_key "potions_alchemical_properties", "alchemical_properties"
  add_foreign_key "potions_alchemical_properties", "potions"
  add_foreign_key "properties", "canonical_properties"
  add_foreign_key "properties", "playthroughs"
  add_foreign_key "recipes_canonical_ingredients", "canonical_ingredients", column: "ingredient_id"
  add_foreign_key "staves", "canonical_staves"
  add_foreign_key "staves", "playthroughs"
  add_foreign_key "weapons", "canonical_weapons"
  add_foreign_key "weapons", "playthroughs"
  add_foreign_key "wish_list_items", "wish_lists", column: "list_id"
  add_foreign_key "wish_lists", "playthroughs"
  add_foreign_key "wish_lists", "wish_lists", column: "aggregate_list_id"
end

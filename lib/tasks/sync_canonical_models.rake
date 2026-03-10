# frozen_string_literal: true

require 'json'

FALSEY_VALUES = [false, 'false'].freeze

namespace :canonical_models do
  namespace :sync do
    desc 'Sync alchemical properties in the database with JSON data'
    task :alchemical_properties, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :alchemical_property, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical enchantments in the database with JSON data'
    task :enchantments, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :enchantment, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical spells in the database with JSON data'
    task :spells, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :spell, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical powers in the database with JSON data'
    task :powers, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :power, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical properties in the database with JSON data'
    task :properties, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :property, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical building and smithing materials in the database with JSON data'
    task :raw_materials, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :raw_material, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical jewelry items in the database with JSON data'
    # rubocop:disable Layout/BlockAlignment
    task :jewelry,
         %i[preserve_existing_records] => %w[
           environment
           canonical_models:sync:enchantments
         ] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :jewelry, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical clothing items in the database with JSON data'
    task :clothing,
         %i[preserve_existing_records] => %w[
           environment
           canonical_models:sync:enchantments
         ] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :clothing, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical armor models in the database with JSON data'
    task :armor,
         %i[preserve_existing_records] => %w[
           environment
           canonical_models:sync:enchantments
         ] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :armor, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical ingredient models in the database with JSON data'
    task :ingredients,
         %i[preserve_existing_records] => %w[
           environment
           canonical_models:sync:alchemical_properties
         ] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :ingredient, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical weapon models in the database with JSON data'
    task :weapons,
         %i[preserve_existing_records] => %w[
           environment
           canonical_models:sync:enchantments
           canonical_models:sync:powers
         ] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :weapon, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical staff models in the database with JSON data'
    task :staves,
         %i[preserve_existing_records] => %w[
           environment
           canonical_models:sync:spells
           canonical_models:sync:powers
         ] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :staff, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical book models in the database with JSON data'
    task :books,
         %i[preserve_existing_records] => %w[
           environment
           canonical_models:sync:ingredients
         ] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :book, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical potion models in the database with JSON data'
    task :potions,
         %i[preserve_existing_records] => %w[
           environment
           canonical_models:sync:alchemical_properties
         ] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :potion, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical misc items in the database with JSON data'
    task :misc_items, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :misc_item, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical crafting material associations in the database with JSON data'
    task :crafting_materials,
         %i[preserve_existing_records] => %w[
           environment
           canonical_models:sync:weapons
           canonical_models:sync:jewelry
           canonical_models:sync:ingredients
           canonical_models:sync:raw_materials
         ] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :crafting_material, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical tempering material associations in the database with JSON data'
    task :tempering_materials,
         %i[preserve_existing_records] => %w[
           environment
           canonical_models:sync:weapons
           canonical_models:sync:armor
           canonical_models:sync:ingredients
           canonical_models:sync:raw_materials
         ] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :tempering_material, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end
    # rubocop:enable Layout/BlockAlignment

    desc 'Sync all canonical models with JSON files'
    task :all, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(model: :all, preserve_existing_records: FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end
  end
end

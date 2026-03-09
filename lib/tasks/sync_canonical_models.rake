# frozen_string_literal: true

require 'json'

FALSEY_VALUES = [false, 'false'].freeze

namespace :canonical_models do
  namespace :sync do
    desc 'Sync alchemical properties in the database with JSON data'
    task :alchemical_properties, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:alchemical_property, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical enchantments in the database with JSON data'
    task :enchantments, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:enchantment, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical spells in the database with JSON data'
    task :spells, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:spell, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical powers in the database with JSON data'
    task :powers, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:power, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical properties in the database with JSON data'
    task :properties, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:property, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical building and smithing materials in the database with JSON data'
    task :raw_materials, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:raw_material, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical jewelry items in the database with JSON data'
    task :jewelry, %i[preserve_existing_records] => %w[environment canonical_models:sync:enchantments] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:jewelry, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical clothing items in the database with JSON data'
    task :clothing, %i[preserve_existing_records] => %w[environment canonical_models:sync:enchantments] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:clothing, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical armor models in the database with JSON data'
    task :armor, %i[preserve_existing_records] => %w[environment canonical_models:sync:enchantments] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:armor, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical ingredient models in the database with JSON data'
    task :ingredients, %i[preserve_existing_records] => %w[environment canonical_models:sync:alchemical_properties] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:ingredient, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical weapon models in the database with JSON data'
    task :weapons, %i[preserve_existing_records] => %w[environment canonical_models:sync:enchantments canonical_models:sync:powers] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:weapon, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical staff models in the database with JSON data'
    task :staves, %i[preserve_existing_records] => %w[environment canonical_models:sync:spells canonical_models:sync:powers] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:staff, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical book models in the database with JSON data'
    task :books, %i[preserve_existing_records] => %w[environment canonical_models:sync:ingredients] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:book, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical potion models in the database with JSON data'
    task :potions, %i[preserve_existing_records] => %w[environment canonical_models:sync:alchemical_properties] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:potion, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical misc items in the database with JSON data'
    task :misc_items, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:misc_item, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical crafting material associations in the database with JSON data'
    task :crafting_materials, %i[preserve_existing_records] => %w[environment canonical_models:sync:weapons canonical_models:sync:jewelry canonical_models:sync:ingredients canonical_models:sync:raw_materials] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:crafting_material, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end

    desc 'Sync canonical tempering material associations in the database with JSON data'
    task :tempering_materials, %i[preserve_existing_records] => %w[environment canonical_models:sync:weapons canonical_models:sync:armor canonical_models:sync:ingredients canonical_models:sync:raw_materials] do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:tempering_material, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end
    desc 'Sync all canonical models with JSON files'
    task :all, %i[preserve_existing_records] => :environment do |_t, args|
      args.with_defaults(preserve_existing_records: false)

      Canonical::Sync.perform(:all, FALSEY_VALUES.exclude?(args[:preserve_existing_records]))
    end
  end
end

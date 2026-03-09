# frozen_string_literal: false

require 'csv'

def concatenate_values(array, *keys_to_concatenate)
  output_value = Array.new(keys_to_concatenate.length)

  keys_to_concatenate.each_with_index do |key, index|
    values = array.pluck(key)

    output_value[index] = values.empty? ? nil : values.join(',')
  end

  output_value.map(&:presence)
end

namespace :csv do
  namespace :export do
    desc 'Export a CSV of canonical alchemical properties from JSON data'
    task alchemical_properties: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'alchemical_properties.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'alchemical_properties.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      headers = "name,description,strength_unit,effects_cumulative\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each {|property| csv << property[:attributes].values }
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of canonical armor items from JSON data'
    task armor: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_armor.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_armor.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      own_property_headers = json_data.first[:attributes].keys.map(&:to_s).join(',')
      headers = "#{own_property_headers},enchantment_names,enchantment_strengths,tempering_material_codes,tempering_material_quantities,crafting_material_codes,crafting_material_quantities\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each do |item|
          enchantment_names, enchantment_strengths = concatenate_values(item[:enchantments], :name, :strength)
          crafting_material_codes, crafting_material_quantities = concatenate_values(item[:crafting_materials], :item_code, :quantity)
          tempering_material_codes, tempering_material_quantities = concatenate_values(item[:tempering_materials], :item_code, :quantity)

          item[:attributes][:smithing_perks] = item[:attributes][:smithing_perks].join(',')

          csv << (item[:attributes].values + [enchantment_names, enchantment_strengths, tempering_material_codes, tempering_material_quantities, crafting_material_codes, crafting_material_quantities])
        end
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of canonical books from JSON data'
    task books: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_books.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_books.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      own_property_headers = json_data.first[:attributes].keys.map(&:to_s).join(',')
      headers = "#{own_property_headers},canonical_ingredient_codes\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each do |item|
          ingredients = item[:canonical_ingredients].pluck(:item_code)
                          .join(',')
          csv << [
            item.dig(:attributes, :title),
            item.dig(:attributes, :title_variants)&.join(';'),
            item.dig(:attributes, :item_code),
            item.dig(:attributes, :unit_weight),
            item.dig(:attributes, :book_type),
            item.dig(:attributes, :skill_name),
            item.dig(:attributes, :purchasable),
            item.dig(:attributes, :unique_item),
            item.dig(:attributes, :rare_item),
            item.dig(:attributes, :solstheim_only),
            item.dig(:attributes, :quest_item),
            ingredients.empty? ? nil : ingredients,
          ]
        end
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of canonical clothing items from JSON data'
    task clothing: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_clothing.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_clothing.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      own_property_headers = json_data.first[:attributes].keys.map(&:to_s).join(',')
      headers = "#{own_property_headers},enchantment_names,enchantment_strengths\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each do |item|
          csv << (item[:attributes].values + concatenate_values(item[:enchantments], :name, :strength))
        end
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of canonical ingredients from JSON data'
    task ingredients: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_ingredients.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_ingredients.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      own_property_headers = json_data.first[:attributes].keys.map(&:to_s).join(',')
      headers = "#{own_property_headers},alchemical_property_names,alchemical_property_priorities\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each do |item|
          csv << (item[:attributes].values + concatenate_values(item[:alchemical_properties], :name, :priority))
        end
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of canonical jewelry items from JSON data'
    task jewelry: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_jewelry.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_jewelry.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      own_property_headers = json_data.first[:attributes].keys.map(&:to_s).join(',')
      headers = "#{own_property_headers},enchantment_names,enchantment_strengths,crafting_material_codes,crafting_material_quantities\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each do |item|
          csv << (item[:attributes].values + concatenate_values(item[:enchantments], :name, :strength) + concatenate_values(item[:crafting_materials], :item_code, :quantity))
        end
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of canonical materials from JSON data'
    task materials: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_materials.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_materials.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      headers = "name,item_code,building_material,smithing_material,unit_weight\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each {|property| csv << property[:attributes].values }
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of canonical properties from JSON data'
    task properties: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_properties.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_properties.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      headers = "name,hold,city,alchemy_lab_available,arcane_enchanter_available,forge_available\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each {|property| csv << property[:attributes].values }
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of canonical staves from JSON data'
    task staves: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_staves.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_staves.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      own_property_headers = json_data.first[:attributes].keys.map(&:to_s).join(',')
      headers = "#{own_property_headers},spell_names,spell_strengths,power_names\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each do |item|
          power_names = item[:powers].pluck(:name)
                          .join(',')

          csv << (item[:attributes].values + concatenate_values(item[:spells], :name, :strength) + [power_names.empty? ? nil : power_names])
        end
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of canonical weapons from JSON data'
    task weapons: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_weapons.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_weapons.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      own_property_headers = json_data.first[:attributes].keys.map(&:to_s).join(',')
      headers = "#{own_property_headers},enchantment_names,enchantment_strengths,tempering_material_codes,tempering_material_quantities,crafting_material_codes,crafting_material_quantities\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each do |item|
          item[:attributes][:smithing_perks] = item.dig(:attributes, :smithing_perks)&.join(',')

          enchantment_names, enchantment_strengths = concatenate_values(item[:enchantments], :name, :strength)
          crafting_material_codes, crafting_material_quantities = concatenate_values(item[:crafting_materials], :item_code, :quantity)
          tempering_material_codes, tempering_material_quantities = concatenate_values(item[:tempering_materials], :item_code, :quantity)

          csv << (item[:attributes].values + [enchantment_names, enchantment_strengths, tempering_material_codes, tempering_material_quantities, crafting_material_codes, crafting_material_quantities])
        end
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of enchantments from JSON data'
    task enchantments: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'enchantments.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'enchantments.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      headers = "#{json_data.first[:attributes].keys.map(&:to_s).join(',')}\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each do |enchantment|
          enchantment[:attributes][:enchantable_items] = enchantment.dig(:attributes, :enchantable_items).join(',')

          csv << enchantment[:attributes].values
        end
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of powers from JSON data'
    task powers: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'powers.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'powers.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      headers = "#{json_data.first[:attributes].keys.map(&:to_s).join(',')}\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each {|power| csv << power[:attributes].values }
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of spells from JSON data'
    task spells: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'spells.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'spells.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      headers = "#{json_data.first[:attributes].keys.map(&:to_s).join(',')}\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each {|spell| csv << spell[:attributes].values }
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of canonical misc items from JSON data'
    task misc_items: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_misc_items.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_misc_items.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      headers = "#{json_data.first[:attributes].keys.map(&:to_s).join(',')}\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each do |item|
          item[:attributes][:item_types] = item.dig(:attributes, :item_types).join(',')

          csv << item[:attributes].values
        end
      end

      File.write(csv_path, csv_data)
    end

    desc 'Export a CSV of canonical potions from JSON data'
    task potions: :environment do
      json_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_potions.json')
      csv_path = Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_potions.csv')
      json_data = JSON.parse(File.read(json_path), symbolize_names: true)

      own_property_headers = json_data.first[:attributes].keys.map(&:to_s).join(',')
      headers = "#{own_property_headers},alchemical_property_names,alchemical_property_strengths,alchemical_property_durations\n"

      csv_data = CSV.generate(headers) do |csv|
        json_data.each do |item|
          csv << (item[:attributes].values + concatenate_values(item[:alchemical_properties], :name, :strength, :duration))
        end
      end

      File.write(csv_path, csv_data)
    end
  end
end

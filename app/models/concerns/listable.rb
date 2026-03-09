# frozen_string_literal: true

module Listable
  extend ActiveSupport::Concern

  included do
    belongs_to :list, class_name: list_class.to_s, touch: true, inverse_of: :list_items

    validates :description, presence: true, uniqueness: { scope: :list_id, case_sensitive: false }
    validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
    validates :unit_weight, numericality: { greater_than_or_equal_to: 0, allow_nil: true }
    validate :no_notes_on_aggregate_item, if: -> { list.aggregate }
    validate :prevent_changed_description, on: :update

    before_save :clean_up_notes

    delegate :game, :user, to: :list

    scope :index_order, -> { order(updated_at: :desc) }
    scope :belonging_to_game, ->(game) { joins(:list).where(list_table_name.to_sym => { game_id: game.id }).order("#{list_table_name}.updated_at DESC") }

    def self.belonging_to_user(user)
      list_ids = list_class.belonging_to_user(user).ids
      joins(:list).where(list_table_name.to_sym => { id: list_ids }).order("#{list_table_name}.updated_at DESC")
    end

    def self.combine_or_create!(attrs)
      obj = combine_or_new(attrs)
      obj.save!
      obj
    end

    def self.combine_or_new(attrs)
      # Make sure the attributes all have symbol keys. This can
      # result in problems if the key types of the attrs differ
      # (e.g., if there is a :unit_weight key and a 'unit_weight'
      # key, only the value of the second one will be preserved)
      new_attrs = {}
      attrs.each {|key, value| new_attrs[key.to_sym] = value }

      list = new_attrs[:list] || list_class.find(new_attrs[:list_id])
      existing_item = list.list_items.find_by('description ILIKE ?', new_attrs[:description])

      new_attrs.delete(:notes) if list.aggregate_list?

      new_attrs[:quantity] ||= 1
      new_attrs[:quantity] += existing_item&.quantity.to_i
      new_attrs[:unit_weight] ||= existing_item&.unit_weight
      new_attrs[:notes] = [existing_item&.notes, new_attrs[:notes]].compact.join(' -- ').presence

      if new_attrs[:unit_weight].nil? && !list.aggregate_list?
        aggregate_item = list.aggregate_list.list_items.find_by('description ILIKE ?', new_attrs[:description])

        new_attrs[:unit_weight] = aggregate_item&.unit_weight
      end

      if existing_item.present?
        existing_item.assign_attributes(new_attrs.except(:description))
        existing_item
      else
        new(new_attrs)
      end
    end
  end

  def prevent_changed_description
    errors.add(:description, 'cannot be updated on an existing list item') if description_changed?
  end

  def no_notes_on_aggregate_item
    errors.add(:notes, 'cannot be present on an aggregate list item') if notes.present?
  end

  def clean_up_notes
    return true unless notes

    self.notes = notes.strip.gsub(/^(-- ?)*/, '').gsub(/( ?--)*$/, '').gsub(/( -- ){2,}/, ' -- ').presence
  end
end

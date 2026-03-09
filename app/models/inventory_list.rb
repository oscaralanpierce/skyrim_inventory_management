# frozen_string_literal: true

require 'titlecase'

class InventoryList < ApplicationRecord
  # Titles have to be unique per game as described in the API docs. They also can only
  # contain alphanumeric characters and spaces with no special characters or whitespace
  # other than spaces. Leading or trailing whitespace is stripped anyway so the validation
  # ignores any leading or trailing whitespace characters.
  validates :title, uniqueness: { scope: :game_id, message: 'must be unique per game', case_sensitive: false }, format: { with: /\A\s*[a-z0-9 \-',]*\s*\z/i, message: "can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')" }

  before_save :format_title

  # This has to be defined before including AggregateListable because its `included` block
  # calls this method.
  def self.list_item_class_name
    'InventoryItem'
  end

  include Aggregatable

  scope :index_order, -> { includes_items.aggregate_first.order(updated_at: :desc) }
  scope :belonging_to_user, ->(user) { joins(:game).where(games: { user_id: user.id }).order('inventory_lists.updated_at DESC') }

  private

  def format_title
    return if aggregate

    if title.blank?
      max_existing_number = game.inventory_lists.where("title LIKE 'My List %'").pluck(:title).map {|t| t.gsub('My List ', '').to_i }
                              .max || 0
      next_number = max_existing_number >= 0 ? max_existing_number + 1 : 1
      self.title = "My List #{next_number}"
    else
      self.title = Titlecase.titleize(title.strip)
    end
  end
end

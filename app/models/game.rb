# frozen_string_literal: true

require 'titlecase'

class Game < ApplicationRecord
  belongs_to :user

  has_many :armors, dependent: :destroy
  has_many :books, dependent: :destroy
  has_many :clothing_items, dependent: :destroy
  has_many :ingredients, dependent: :destroy
  has_many :jewelry_items, dependent: :destroy
  has_many :misc_items, dependent: :destroy
  has_many :potions, dependent: :destroy
  has_many :properties, dependent: :destroy
  has_many :staves, dependent: :destroy
  has_many :weapons, dependent: :destroy

  # `before_save` callbacks need to be defined before
  # `before_destroy` callbacks, which need to be defined here
  # (see comment below).
  before_save :format_name

  # Relations to `Aggregatable` child models have to be defined
  # after this `before_destroy` callback. `dependent: :destroy`
  # is implemented as a `before_destroy` callback itself and,
  # since callbacks of the same type run in the order they're
  # defined, any `before_destroy` callbacks that need to be run
  # before `dependent: :destroy` need to be defined before the
  # association is defined.
  before_destroy :destroy_aggregatable_child_models
  has_many :wish_lists, -> { index_order }, dependent: :destroy, inverse_of: :game
  has_many :inventory_lists, -> { index_order }, dependent: :destroy, inverse_of: :game

  validates :name, uniqueness: { scope: :user_id, message: 'must be unique', case_sensitive: false }, format: { with: /\A\s*[a-z0-9 \-',]*\s*\z/i, message: "can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')" }

  scope :index_order, -> { order(updated_at: :desc) }

  def aggregate_wish_list
    wish_lists.find_by(aggregate: true)
  end

  def aggregate_inventory_list
    inventory_lists.find_by(aggregate: true)
  end

  def wish_list_items
    WishListItem.belonging_to_game(self)
  end

  def inventory_items
    InventoryItem.belonging_to_game(self)
  end

  private

  def format_name
    if name.blank?
      max_existing_number = user.games.where("name LIKE 'My Game %'").pluck(:name).map {|t| t.gsub('My Game ', '').to_i }
                              .max || 0
      next_number = max_existing_number >= 0 ? max_existing_number + 1 : 1
      self.name = "My Game #{next_number}"
    else
      self.name = Titlecase.titleize(name.strip)
    end
  end

  # This is necessary because `dependent: :destroy` will destroy the child
  # models in `index_order`, which is aggregate list first. Aggregate lists
  # can't be destroyed until after all their child lists have been destroyed.
  # Since there is no way to change the order in which the child models are
  # deleted, it's necessary to do it in a before hook.
  def destroy_aggregatable_child_models
    wish_lists.reverse.each(&:destroy)
    inventory_lists.reverse.each(&:destroy)
  end
end

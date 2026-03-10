# frozen_string_literal: true

require 'service/internal_server_error_result'
require 'service/method_not_allowed_result'
require 'service/not_found_result'
require 'service/ok_result'

class WishListsController < ApplicationController
  class DestroyService
    AGGREGATE_LIST_ERROR = 'Cannot manually delete an aggregate wish list'

    def initialize(user, list_id)
      @user = user
      @list_id = list_id
    end

    def perform
      return Service::MethodNotAllowedResult.new(errors: [AGGREGATE_LIST_ERROR]) if wish_list.aggregate == true

      ids = game.wish_lists.count == 2 ? [aggregate_list.id, wish_list.id] : [wish_list.id]

      destroy_and_update_aggregate_list_items!

      resource = aggregate_list&.persisted? ? { deleted: ids, aggregate: aggregate_list } : { deleted: ids }

      Service::OkResult.new(resource:)
    rescue ActiveRecord::RecordNotFound
      Service::NotFoundResult.new
    rescue StandardError => e
      Rails.logger.error("Internal Server Error: #{e.message}")
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :list_id

    def wish_list
      @wish_list ||= user.wish_lists.find(list_id)
    end

    def aggregate_list
      game.aggregate_wish_list
    end

    def game
      @game ||= wish_list.game
    end

    def destroy_and_update_aggregate_list_items!
      aggregate_list = wish_list.aggregate_list

      list_items = wish_list.list_items.map(&:attributes)

      ActiveRecord::Base.transaction do
        # If wish_list is the user's last regular wish list, this will also
        # destroy their aggregate list (see the Aggregatable concern)
        wish_list.destroy!

        list_items.each {|item_attributes| aggregate_list.remove_item_from_child_list(item_attributes) } if aggregate_list&.persisted?
      end
    end
  end
end

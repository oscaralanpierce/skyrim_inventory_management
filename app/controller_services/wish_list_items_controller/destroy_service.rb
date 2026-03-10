# frozen_string_literal: true

require 'service/internal_server_error_result'
require 'service/method_not_allowed_result'
require 'service/not_found_result'
require 'service/ok_result'

class WishListItemsController < ApplicationController
  class DestroyService
    AGGREGATE_LIST_ERROR = 'Cannot manually delete list item from aggregate wish list'

    def initialize(user, item_id)
      @user = user
      @item_id = item_id
    end

    def perform
      return Service::MethodNotAllowedResult.new(errors: [AGGREGATE_LIST_ERROR]) if wish_list.aggregate == true

      ActiveRecord::Base.transaction do
        wish_list_item.destroy!
        aggregate_list.remove_item_from_child_list(wish_list_item.attributes)
      end

      Service::OkResult.new(resource: [aggregate_list.reload, wish_list.reload])
    rescue ActiveRecord::RecordNotFound
      Service::NotFoundResult.new
    rescue StandardError => e
      Rails.logger.error("Internal Server Error: #{e.message}")
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :item_id

    def game
      @game ||= wish_list.game
    end

    def aggregate_list
      @aggregate_list ||= wish_list.aggregate_list
    end

    def wish_list
      @wish_list = wish_list_item.list
    end

    def wish_list_item
      @wish_list_item ||= user.wish_list_items.find(item_id)
    end
  end
end

# frozen_string_literal: true

require 'service/internal_server_error_result'
require 'service/method_not_allowed_result'
require 'service/no_content_result'
require 'service/not_found_result'
require 'service/ok_result'

class InventoryItemsController < ApplicationController
  class DestroyService
    AGGREGATE_LIST_ERROR = 'Cannot manually delete list item from aggregate inventory list'

    def initialize(user, item_id)
      @user = user
      @item_id = item_id
    end

    def perform
      return Service::MethodNotAllowedResult.new(errors: [AGGREGATE_LIST_ERROR]) if inventory_list.aggregate == true

      aggregate_list_item = nil

      ActiveRecord::Base.transaction do
        list_item.destroy!
        aggregate_list_item = aggregate_list.remove_item_from_child_list(list_item.attributes)
      end

      aggregate_list_item.nil? ? Service::NoContentResult.new : Service::OkResult.new(resource: aggregate_list_item)
    rescue ActiveRecord::RecordNotFound
      Service::NotFoundResult.new
    rescue StandardError => e
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :item_id

    def aggregate_list
      @aggregate_list ||= inventory_list.aggregate_list
    end

    def inventory_list
      @inventory_list ||= list_item.list
    end

    def list_item
      @list_item ||= user.inventory_items.find(item_id)
    end
  end
end

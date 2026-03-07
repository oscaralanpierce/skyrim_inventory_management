# frozen_string_literal: true

require 'service/ok_result'
require 'service/no_content_result'
require 'service/method_not_allowed_result'
require 'service/not_found_result'
require 'service/internal_server_error_result'

class InventoryListsController < ApplicationController
  class DestroyService
    AGGREGATE_LIST_ERROR = 'Cannot manually delete an aggregate inventory list'

    def initialize(user, list_id)
      @user = user
      @list_id = list_id
    end

    def perform
      return Service::MethodNotAllowedResult.new(errors: [AGGREGATE_LIST_ERROR]) if inventory_list.aggregate == true

      aggregate_list = destroy_and_update_aggregate_list_items
      aggregate_list.nil? ? Service::NoContentResult.new : Service::OkResult.new(resource: aggregate_list)
    rescue ActiveRecord::RecordNotFound
      Service::NotFoundResult.new
    rescue StandardError => e
      Rails.logger.error("Internal Server Error: #{e.message}")
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :list_id

    def destroy_and_update_aggregate_list_items
      aggregate_list = inventory_list.aggregate_list
      list_items = inventory_list.list_items.map(&:attributes)

      ActiveRecord::Base.transaction do
        # If inventory_list is the user's last regular inventory list, this will also
        # destroy their aggregate list
        inventory_list.destroy!

        if aggregate_list&.persisted?
          list_items.each {|item_attributes| aggregate_list.remove_item_from_child_list(item_attributes) }
          aggregate_list
        end
      end
    end

    def inventory_list
      @inventory_list ||= user.inventory_lists.find(list_id)
    end
  end
end

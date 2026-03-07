# frozen_string_literal: true

require 'service/ok_result'
require 'service/not_found_result'
require 'service/unprocessable_entity_result'
require 'service/method_not_allowed_result'
require 'service/internal_server_error_result'

class InventoryItemsController < ApplicationController
  class UpdateService
    AGGREGATE_LIST_ERROR = 'Cannot manually update list items on an aggregate inventory list'

    def initialize(user, item_id, params)
      @user = user
      @item_id = item_id
      @params = params
    end

    def perform
      return Service::MethodNotAllowedResult.new(errors: [AGGREGATE_LIST_ERROR]) if inventory_list.aggregate == true

      changed_attributes = {}
      changed_attributes[:quantity] = { from: list_item.quantity, to: params[:quantity] } if quantity_changed?
      changed_attributes[:unit_weight] = { to: params[:unit_weight] } if unit_weight_changed?

      # Declare aggregate_list_item variable to make it available outside the
      # transaction block
      aggregate_list_item = nil

      ActiveRecord::Base.transaction do
        list_item.update!(params)

        aggregate_list_item = aggregate_list.update_item_from_child_list(list_item.description, changed_attributes)
      end

      resource = params[:unit_weight] ? all_matching_items : [aggregate_list_item, list_item]

      Service::OkResult.new(resource:)
    rescue ActiveRecord::RecordInvalid
      Service::UnprocessableEntityResult.new(errors: list_item.error_array)
    rescue ActiveRecord::RecordNotFound
      Service::NotFoundResult.new
    rescue StandardError => e
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :item_id, :params

    def aggregate_list
      @aggregate_list ||= list_item.list.aggregate_list
    end

    def inventory_list
      @inventory_list ||= list_item.list
    end

    def list_item
      @list_item ||= user.inventory_items.find(item_id)
    end

    def quantity_changed?
      params.has_key?(:quantity) && params[:quantity] != list_item.quantity
    end

    def unit_weight_changed?
      params.has_key?(:unit_weight) && params[:unit_weight] != list_item.unit_weight
    end

    def all_matching_items
      aggregate_list.game.inventory_items.where('description ILIKE ?', list_item.description)
    end
  end
end

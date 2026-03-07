# frozen_string_literal: true

require 'service/ok_result'
require 'service/not_found_result'
require 'service/unprocessable_entity_result'
require 'service/method_not_allowed_result'
require 'service/internal_server_error_result'

class WishListItemsController < ApplicationController
  class UpdateService
    AGGREGATE_LIST_ERROR = 'Cannot manually update list items on an aggregate wish list'

    def initialize(user, item_id, params)
      @user = user
      @item_id = item_id
      @params = params
    end

    def perform
      return Service::MethodNotAllowedResult.new(errors: [AGGREGATE_LIST_ERROR]) if wish_list.aggregate == true

      changed_attributes = {}
      changed_attributes[:quantity] = { from: list_item.quantity, to: params[:quantity] } if quantity_changed?
      changed_attributes[:unit_weight] = { to: params[:unit_weight] } if unit_weight_changed?

      ActiveRecord::Base.transaction do
        list_item.update!(params)
        aggregate_list.update_item_from_child_list(list_item.description, changed_attributes)
      end

      Service::OkResult.new(
        resource: changed_attributes[:unit_weight].present? ? all_matching_items : [aggregate_list_item, list_item.reload],
      )
    rescue ActiveRecord::RecordInvalid
      Service::UnprocessableEntityResult.new(errors: list_item.error_array)
    rescue ActiveRecord::RecordNotFound
      Service::NotFoundResult.new
    rescue StandardError => e
      Rails.logger.error "Internal Server Error: #{e.message}"
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :item_id, :params

    def aggregate_list
      @aggregate_list ||= list_item.list.aggregate_list
    end

    def wish_list
      @wish_list ||= list_item.list
    end

    def list_item
      @list_item ||= user.wish_list_items.find(item_id)
    end

    def game
      @game ||= wish_list.game
    end

    def aggregate_list_item
      aggregate_list.list_items.find_by('description ILIKE ?', list_item.description)
    end

    def quantity_changed?
      params[:quantity].present? && params[:quantity] != list_item.quantity
    end

    def unit_weight_changed?
      params.has_key?(:unit_weight) && params[:unit_weight] != list_item.unit_weight
    end

    def all_matching_items
      aggregate_list.game.wish_list_items.where('description ILIKE ?', list_item.description)
    end
  end
end

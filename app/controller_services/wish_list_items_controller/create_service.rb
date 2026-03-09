# frozen_string_literal: true

require 'service/created_result'
require 'service/ok_result'
require 'service/not_found_result'
require 'service/unprocessable_entity_result'
require 'service/method_not_allowed_result'
require 'service/internal_server_error_result'

class WishListItemsController < ApplicationController
  class CreateService
    AGGREGATE_LIST_ERROR = 'Cannot manually manage items on an aggregate wish list'

    def initialize(user, list_id, params)
      @user = user
      @list_id = list_id
      @params = params
    end

    def perform
      return Service::MethodNotAllowedResult.new(errors: [AGGREGATE_LIST_ERROR]) if wish_list.aggregate == true

      preexisting_item = wish_list.list_items.find_by('description ILIKE ?', params[:description])
      item = WishListItem.combine_or_new(params.merge(list_id:))

      ActiveRecord::Base.transaction do
        lists_changed = lists_to_be_changed

        item.save!

        if preexisting_item.blank?
          aggregate_list.add_item_from_child_list(item)

          Service::CreatedResult.new(resource: lists_changed)
        else
          changed_attributes = {}
          changed_attributes[:quantity] = { from: 0, to: params[:quantity] }
          changed_attributes[:unit_weight] = { to: params[:unit_weight] } if params[:unit_weight]

          aggregate_list.update_item_from_child_list(params[:description], changed_attributes)

          Service::OkResult.new(resource: lists_changed)
        end
      end
    rescue ActiveRecord::RecordInvalid
      Service::UnprocessableEntityResult.new(errors: item.error_array)
    rescue ActiveRecord::RecordNotFound
      Service::NotFoundResult.new
    rescue StandardError => e
      Rails.logger.error "Internal Server Error: #{e.message}"
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :list_id, :params

    def wish_list
      @wish_list ||= user.wish_lists.find(list_id)
    end

    def aggregate_list
      @aggregate_list ||= wish_list.aggregate_list
    end

    def game
      @game ||= aggregate_list.game
    end

    def aggregate_list_item
      @aggregate_list_item ||= aggregate_list.list_items.find_by('description ILIKE ?', params[:description])
    end

    def all_matching_list_items
      @all_matching_list_items ||= game.wish_list_items.where(
        'description ILIKE ?',
        params[:description],
      )
    end

    def lists_to_be_changed
      list_ids = if all_matching_list_items.count > 0 && params[:unit_weight] && params[:unit_weight] != aggregate_list_item&.unit_weight
                   all_matching_list_items.pluck(:list_id).push(wish_list.id)
                 else
                   [aggregate_list.id, wish_list.id]
                 end

      game.wish_lists.where(id: list_ids)
    end
  end
end

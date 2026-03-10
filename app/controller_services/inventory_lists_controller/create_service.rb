# frozen_string_literal: true

require 'service/created_result'
require 'service/internal_server_error_result'
require 'service/not_found_result'
require 'service/unprocessable_entity_result'

class InventoryListsController < ApplicationController
  class CreateService
    AGGREGATE_LIST_ERROR = 'Cannot manually create an aggregate inventory list'

    def initialize(user, game_id, params)
      @user = user
      @game_id = game_id
      @params = params
    end

    def perform
      return Service::UnprocessableEntityResult.new(errors: [AGGREGATE_LIST_ERROR]) if params[:aggregate]

      inventory_list = game.inventory_lists.new(params)
      preexisting_aggregate_list = game.aggregate_inventory_list

      if inventory_list.save
        resource = preexisting_aggregate_list ? inventory_list : [game.aggregate_inventory_list, inventory_list]
        Service::CreatedResult.new(resource:)
      else
        Service::UnprocessableEntityResult.new(errors: inventory_list.error_array)
      end
    rescue ActiveRecord::RecordNotFound
      Service::NotFoundResult.new
    rescue StandardError => e
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :game_id, :params

    def game
      @game ||= user.games.find(game_id)
    end
  end
end

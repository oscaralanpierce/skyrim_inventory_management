# frozen_string_literal: true

require 'service/created_result'
require 'service/internal_server_error_result'
require 'service/method_not_allowed_result'
require 'service/not_found_result'
require 'service/ok_result'
require 'service/unprocessable_entity_result'

class WishListsController < ApplicationController
  class CreateService
    AGGREGATE_LIST_ERROR = 'Cannot manually create an aggregate wish list'

    def initialize(user, game_id, params)
      @user = user
      @game_id = game_id
      @params = params
    end

    def perform
      return Service::UnprocessableEntityResult.new(errors: [AGGREGATE_LIST_ERROR]) if params[:aggregate]

      wish_list = game.wish_lists.new(params)

      if wish_list.save
        resource = game_has_other_lists? ? Array.wrap(wish_list) : game.wish_lists.index_order
        Service::CreatedResult.new(resource:)
      else
        Service::UnprocessableEntityResult.new(errors: wish_list.error_array)
      end
    rescue ActiveRecord::RecordNotFound
      Service::NotFoundResult.new
    rescue StandardError => e
      Rails.logger.error("Internal Server Error: #{e.message}")
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :game_id, :params

    def game
      @game ||= user.games.find(game_id)
    end

    def game_has_other_lists?
      game.wish_lists.count > 2
    end
  end
end

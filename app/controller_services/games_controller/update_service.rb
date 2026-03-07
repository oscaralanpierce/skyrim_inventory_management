# frozen_string_literal: true

require 'service/ok_result'
require 'service/unprocessable_entity_result'
require 'service/not_found_result'
require 'service/internal_server_error_result'

class GamesController < ApplicationController
  class UpdateService
    def initialize(user, game_id, params)
      @user = user
      @game_id = game_id
      @params = params
    end

    def perform
      if game.update(params)
        Service::OkResult.new(resource: game)
      else
        Service::UnprocessableEntityResult.new(errors: game.error_array)
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

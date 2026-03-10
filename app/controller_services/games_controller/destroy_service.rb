# frozen_string_literal: true

require 'service/internal_server_error_result'
require 'service/no_content_result'
require 'service/not_found_result'

class GamesController < ApplicationController
  class DestroyService
    def initialize(user, game_id)
      @user = user
      @game_id = game_id
    end

    def perform
      game.destroy!
      Service::NoContentResult.new
    rescue ActiveRecord::RecordNotFound
      Service::NotFoundResult.new
    rescue StandardError => e
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :game_id

    def game
      @game ||= user.games.find(game_id)
    end
  end
end

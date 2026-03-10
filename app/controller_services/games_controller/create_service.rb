# frozen_string_literal: true

require 'service/created_result'
require 'service/internal_server_error_result'
require 'service/unprocessable_entity_result'

class GamesController < ApplicationController
  class CreateService
    def initialize(user, params)
      @user = user
      @params = params
    end

    def perform
      game = user.games.new(params)
      if game.save
        Service::CreatedResult.new(resource: game)
      else
        Service::UnprocessableEntityResult.new(errors: game.error_array)
      end
    rescue StandardError => e
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :params
  end
end

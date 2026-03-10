# frozen_string_literal: true

require 'service/not_found_result'
require 'service/ok_result'

class InventoryListsController < ApplicationController
  class IndexService
    def initialize(user, game_id)
      @user = user
      @game_id = game_id
    end

    def perform
      Service::OkResult.new(resource: game.inventory_lists)
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

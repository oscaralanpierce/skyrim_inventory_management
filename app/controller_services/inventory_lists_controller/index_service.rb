# frozen_string_literal: true

require 'service/not_found_result'
require 'service/ok_result'

class InventoryListsController < ApplicationController
  class IndexService
    def initialize(user, playthrough_id)
      @user = user
      @playthrough_id = playthrough_id
    end

    def perform
      Service::OkResult.new(resource: playthrough.inventory_lists)
    rescue ActiveRecord::RecordNotFound
      Service::NotFoundResult.new
    rescue StandardError => e
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :playthrough_id

    def playthrough
      @playthrough ||= user.playthroughs.find(playthrough_id)
    end
  end
end

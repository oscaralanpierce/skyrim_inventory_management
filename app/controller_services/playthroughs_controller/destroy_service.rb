# frozen_string_literal: true

require 'service/internal_server_error_result'
require 'service/no_content_result'
require 'service/not_found_result'

class PlaythroughsController < ApplicationController
  class DestroyService
    def initialize(user, playthrough_id)
      @user = user
      @playthrough_id = playthrough_id
    end

    def perform
      playthrough.destroy!
      Service::NoContentResult.new
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

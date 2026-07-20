# frozen_string_literal: true

require 'service/internal_server_error_result'
require 'service/not_found_result'
require 'service/ok_result'
require 'service/unprocessable_entity_result'

class PlaythroughsController < ApplicationController
  class UpdateService
    def initialize(user, playthrough_id, params)
      @user = user
      @playthrough_id = playthrough_id
      @params = params
    end

    def perform
      if playthrough.update(params)
        Service::OkResult.new(resource: playthrough)
      else
        Service::UnprocessableEntityResult.new(errors: playthrough.error_array)
      end
    rescue ActiveRecord::RecordNotFound
      Service::NotFoundResult.new
    rescue StandardError => e
      Service::InternalServerErrorResult.new(errors: [e.message])
    end

    private

    attr_reader :user, :playthrough_id, :params

    def playthrough
      @playthrough ||= user.playthroughs.find(playthrough_id)
    end
  end
end

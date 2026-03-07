# frozen_string_literal: true

require 'service/ok_result'
require 'service/method_not_allowed_result'
require 'service/not_found_result'
require 'service/unprocessable_entity_result'
require 'service/internal_server_error_result'

class WishListsController < ApplicationController
  class UpdateService
    AGGREGATE_LIST_ERROR = 'Cannot manually update an aggregate wish list'
    DISALLOWED_UPDATE_ERROR = 'Cannot make a regular wish list an aggregate list'

    def initialize(user, list_id, params)
      @user = user
      @list_id = list_id
      @params = params
    end

    def perform
      return Service::MethodNotAllowedResult.new(errors: [AGGREGATE_LIST_ERROR]) if wish_list.aggregate == true
      return Service::UnprocessableEntityResult.new(errors: [DISALLOWED_UPDATE_ERROR]) if params[:aggregate] == true

      if wish_list.update(params)
        Service::OkResult.new(resource: wish_list)
      else
        Service::UnprocessableEntityResult.new(errors: wish_list.error_array)
      end
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
  end
end

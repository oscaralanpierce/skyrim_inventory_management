# frozen_string_literal: true

require 'controller/response'
require 'service/ok_result'

class HealthChecksController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    result = Service::OkResult.new(resource: {})

    ::Controller::Response.new(self, result).execute
  end
end

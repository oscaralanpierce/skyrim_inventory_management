# frozen_string_literal: true

require 'service/ok_result'
require 'controller/response'

class HealthChecksController < ApplicationController
  skip_before_action :authenticate_user!

  def index
    result = Service::OkResult.new(resource: {})

    ::Controller::Response.new(self, result).execute
  end
end

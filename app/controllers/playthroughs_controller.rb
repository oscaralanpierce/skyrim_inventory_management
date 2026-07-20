# frozen_string_literal: true

require 'controller/response'

class PlaythroughsController < ApplicationController
  def index
    result = IndexService.new(current_user).perform

    ::Controller::Response.new(self, result).execute
  end

  def create
    result = CreateService.new(current_user, game_params).perform

    ::Controller::Response.new(self, result).execute
  end

  def update
    result = UpdateService.new(current_user, params[:id], game_params).perform

    ::Controller::Response.new(self, result).execute
  end

  def destroy
    result = DestroyService.new(current_user, params[:id]).perform

    ::Controller::Response.new(self, result).execute
  end

  private

  def game_params
    params.require(:playthrough).permit(:name, :description)
  end
end

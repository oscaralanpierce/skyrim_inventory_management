# frozen_string_literal: true

require 'controller/response'

class WishListsController < ApplicationController
  def index
    result = IndexService.new(current_user, params[:playthrough_id]).perform

    ::Controller::Response.new(self, result).execute
  end

  def create
    result = CreateService.new(current_user, params[:playthrough_id], wish_list_params).perform

    ::Controller::Response.new(self, result).execute
  end

  def update
    result = UpdateService.new(current_user, params[:id], wish_list_params).perform

    ::Controller::Response.new(self, result).execute
  end

  def destroy
    result = DestroyService.new(current_user, params[:id]).perform

    ::Controller::Response.new(self, result).execute
  end

  private

  def wish_list_params
    params[:wish_list].present? ? params.require(:wish_list).permit(:title, :aggregate) : {}
  end
end

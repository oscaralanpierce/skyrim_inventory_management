# frozen_string_literal: true

require 'controller/response'

class WishListItemsController < ApplicationController
  def create
    result = CreateService.new(current_user, params[:wish_list_id], list_item_params).perform

    ::Controller::Response.new(self, result).execute
  end

  def update
    result = UpdateService.new(current_user, params[:id], list_item_params).perform

    ::Controller::Response.new(self, result).execute
  end

  def destroy
    result = DestroyService.new(current_user, params[:id]).perform

    ::Controller::Response.new(self, result).execute
  end

  private

  def list_item_params
    params.require(:wish_list_item).permit(
      :description,
      :quantity,
      :notes,
      :unit_weight,
    )
  end
end

# frozen_string_literal: true

require 'controller/response'

class InventoryItemsController < ApplicationController
  def create
    result = CreateService.new(current_user, params[:inventory_list_id], list_item_params).perform

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
    params.require(:inventory_item).permit(
      :description,
      :quantity,
      :notes,
      :unit_weight,
    )
  end
end

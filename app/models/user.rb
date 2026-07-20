# frozen_string_literal: true

class User < ApplicationRecord
  has_many :playthroughs, dependent: :destroy

  validates :uid, presence: true, uniqueness: true
  validates :email, presence: true

  def self.create_or_update_for_google(data)
    where(uid: data['localId']).first_or_initialize.tap do |user|
      user.uid = data['localId']
      user.email = data['email']
      user.display_name = data['displayName']
      user.photo_url = data['photoUrl']
      user.save!
    end
  end

  def wish_lists
    WishList.belonging_to_user(self)
  end

  def inventory_lists
    InventoryList.belonging_to_user(self)
  end

  def wish_list_items
    WishListItem.belonging_to_user(self)
  end

  def inventory_items
    InventoryItem.belonging_to_user(self)
  end
end

# frozen_string_literal: true

class HomesteadValidator < ActiveModel::Validator
  WEST_WING_MESSAGE = "can only have one of enchanter's tower, bedrooms, or greenhouse"
  NORTH_WING_MESSAGE = 'can only have one of alchemy tower, storage room, or trophy room'
  EAST_WING_MESSAGE = 'can only have one of library, armory, or kitchen'

  def validate(record)
    @record = record

    if record.homestead?
      validate_west_wing
      validate_north_wing
      validate_east_wing
    else
      validate_no_homestead_fields
    end
  end

  private

  attr_reader :record

  def validate_west_wing
    west_wing_rooms = [record.has_enchanters_tower, record.has_bedrooms, record.has_greenhouse]

    record.errors.add(:west_wing, WEST_WING_MESSAGE) if west_wing_rooms.count(true) > 1
  end

  def validate_east_wing
    east_wing_rooms = [record.has_library, record.has_armory, record.has_kitchen]

    record.errors.add(:east_wing, EAST_WING_MESSAGE) if east_wing_rooms.count(true) > 1
  end

  def validate_north_wing
    north_wing_rooms = [record.has_alchemy_tower, record.has_storage_room, record.has_trophy_room]

    record.errors.add(:north_wing, NORTH_WING_MESSAGE) if north_wing_rooms.count(true) > 1
  end

  def validate_no_homestead_fields
    record.errors.add(:has_cellar, not_homestead_message('a cellar')) if record.has_cellar
    record.errors.add(:has_main_hall, not_homestead_message('a main hall')) if record.has_main_hall
    record.errors.add(:has_enchanters_tower, not_homestead_message("an enchanter's tower")) if record.has_enchanters_tower
    record.errors.add(:has_alchemy_tower, not_homestead_message('an alchemy tower')) if record.has_alchemy_tower
    record.errors.add(:has_library, not_homestead_message('a library')) if record.has_library
    record.errors.add(:has_bedrooms, not_homestead_message('bedrooms')) if record.has_bedrooms
    record.errors.add(:has_storage_room, not_homestead_message('a storage room')) if record.has_storage_room
    record.errors.add(:has_armory, not_homestead_message('an armory')) if record.has_armory
    record.errors.add(:has_greenhouse, not_homestead_message('a greenhouse')) if record.has_greenhouse
    record.errors.add(:has_trophy_room, not_homestead_message('a trophy room')) if record.has_trophy_room
    record.errors.add(:has_kitchen, not_homestead_message('a kitchen')) if record.has_kitchen
  end

  def not_homestead_message(feature)
    "cannot be true because this property cannot have #{feature} in Skyrim"
  end
end

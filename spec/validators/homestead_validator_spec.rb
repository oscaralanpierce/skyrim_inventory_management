# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HomesteadValidator do
  subject(:validate) { described_class.new.validate(property) }

  # rubocop:disable RSpec/BeforeAfterAll
  before(:all) { Rails.application.load_tasks }
  # rubocop:enable RSpec/BeforeAfterAll

  before { Rake::Task['canonical_models:sync:properties'].invoke }

  after { Rake::Task['canonical_models:sync:properties'].reenable }

  context 'when the property is not a homestead' do
    let(:property) { build(:property, name: 'Breezehome') }

    it 'validates that there is no cellar' do
      property.has_cellar = true
      validate
      expect(property.errors[:has_cellar]).to include 'cannot be true because this property cannot have a cellar in Skyrim'
    end

    it 'validates that there is no main hall' do
      property.has_main_hall = true
      validate
      expect(property.errors[:has_main_hall]).to include 'cannot be true because this property cannot have a main hall in Skyrim'
    end

    it "validates that there is no enchanter's tower" do
      property.has_enchanters_tower = true
      validate
      expect(property.errors[:has_enchanters_tower]).to include "cannot be true because this property cannot have an enchanter's tower in Skyrim"
    end

    it 'validates that there is no alchemy tower' do
      property.has_alchemy_tower = true
      validate
      expect(property.errors[:has_alchemy_tower]).to include 'cannot be true because this property cannot have an alchemy tower in Skyrim'
    end

    it 'validates that there is no library' do
      property.has_library = true
      validate
      expect(property.errors[:has_library]).to include 'cannot be true because this property cannot have a library in Skyrim'
    end

    it 'validates that there are no bedrooms' do
      property.has_bedrooms = true
      validate
      expect(property.errors[:has_bedrooms]).to include 'cannot be true because this property cannot have bedrooms in Skyrim'
    end

    it 'validates that there is no storage room' do
      property.has_storage_room = true
      validate
      expect(property.errors[:has_storage_room]).to include 'cannot be true because this property cannot have a storage room in Skyrim'
    end

    it 'validates that there is no armory' do
      property.has_armory = true
      validate
      expect(property.errors[:has_armory]).to include 'cannot be true because this property cannot have an armory in Skyrim'
    end

    it 'validates that there is no greenhouse' do
      property.has_greenhouse = true
      validate
      expect(property.errors[:has_greenhouse]).to include 'cannot be true because this property cannot have a greenhouse in Skyrim'
    end

    it 'validates that there is no trophy room' do
      property.has_trophy_room = true
      validate
      expect(property.errors[:has_trophy_room]).to include 'cannot be true because this property cannot have a trophy room in Skyrim'
    end

    it 'validates that there is no kitchen' do
      property.has_kitchen = true
      validate
      expect(property.errors[:has_kitchen]).to include 'cannot be true because this property cannot have a kitchen in Skyrim'
    end
  end

  context 'when the property is a homestead' do
    let(:property) { build(:property, name: 'Heljarchen Hall') }

    it 'allows a cellar' do
      property.has_cellar = true
      validate
      expect(property.errors[:has_cellar]).to be_blank
    end

    describe 'west wing' do
      context 'when multiple west-wing rooms are specified' do
        context "when there is an enchanter's tower and bedrooms" do
          it 'adds an error' do
            property.has_enchanters_tower = true
            property.has_bedrooms = true
            validate
            expect(property.errors[:west_wing]).to include "can only have one of enchanter's tower, bedrooms, or greenhouse"
          end
        end

        context "when there is an enchanter's tower and a greenhouse" do
          it 'adds an error' do
            property.has_enchanters_tower = true
            property.has_greenhouse = true
            validate
            expect(property.errors[:west_wing]).to include "can only have one of enchanter's tower, bedrooms, or greenhouse"
          end
        end

        context 'when there are bedrooms and a greenhouse' do
          it 'adds an error' do
            property.has_bedrooms = true
            property.has_greenhouse = true
            validate
            expect(property.errors[:west_wing]).to include "can only have one of enchanter's tower, bedrooms, or greenhouse"
          end
        end

        context 'when there are all three' do
          it 'adds an error' do
            property.has_enchanters_tower = true
            property.has_bedrooms = true
            property.has_greenhouse = true
            validate
            expect(property.errors[:west_wing]).to include "can only have one of enchanter's tower, bedrooms, or greenhouse"
          end
        end
      end

      context 'when a single west-wing room is specified' do
        context "when there is an enchanter's tower" do
          it "doesn't add an error" do
            property.has_enchanters_tower = true
            validate
            expect(property.errors[:west_wing]).to be_blank
          end
        end

        context 'when there is a greenhouse' do
          it "doesn't add an error" do
            property.has_greenhouse = true
            validate
            expect(property.errors[:west_wing]).to be_blank
          end
        end

        context 'when there are bedrooms' do
          it "doesn't add an error" do
            property.has_bedrooms = true
            validate
            expect(property.errors[:west_wing]).to be_blank
          end
        end
      end

      context 'when there are no west-wing rooms' do
        it "doesn't add an error" do
          validate
          expect(property.errors[:west_wing]).to be_blank
        end
      end
    end

    describe 'north wing' do
      context 'when multiple north-wing rooms are specified' do
        context 'when there is an alchemy tower and a storage room' do
          it 'adds an error' do
            property.has_alchemy_tower = true
            property.has_storage_room = true
            validate
            expect(property.errors[:north_wing]).to include 'can only have one of alchemy tower, storage room, or trophy room'
          end
        end

        context 'when there is an alchemy tower and a trophy room' do
          it 'adds an error' do
            property.has_alchemy_tower = true
            property.has_trophy_room = true
            validate
            expect(property.errors[:north_wing]).to include 'can only have one of alchemy tower, storage room, or trophy room'
          end
        end

        context 'when there is a storage room and a trophy room' do
          it 'adds an error' do
            property.has_storage_room = true
            property.has_trophy_room = true
            validate
            expect(property.errors[:north_wing]).to include 'can only have one of alchemy tower, storage room, or trophy room'
          end
        end

        context 'when there are all three' do
          it 'adds an error' do
            property.has_alchemy_tower = true
            property.has_storage_room = true
            property.has_trophy_room = true
            validate
            expect(property.errors[:north_wing]).to include 'can only have one of alchemy tower, storage room, or trophy room'
          end
        end
      end

      context 'when a single north-wing room is specified' do
        context 'when there is an alchemy tower' do
          it "doesn't add an error" do
            property.has_alchemy_tower = true
            validate
            expect(property.errors[:north_wing]).to be_blank
          end
        end

        context 'when there is a storage room' do
          it "doesn't add an error" do
            property.has_storage_room = true
            validate
            expect(property.errors[:north_wing]).to be_blank
          end
        end

        context 'when there is a trophy room' do
          it "doesn't add an error" do
            property.has_trophy_room = true
            validate
            expect(property.errors[:north_wing]).to be_blank
          end
        end
      end

      context 'when there are no north-wing rooms' do
        it "doesn't add an error" do
          validate
          expect(property.errors[:north_wing]).to be_blank
        end
      end
    end

    describe 'east wing' do
      context 'when multiple east-wing rooms are specified' do
        context 'when there is a library and an armory' do
          it 'adds an error' do
            property.has_library = true
            property.has_armory = true
            validate
            expect(property.errors[:east_wing]).to include 'can only have one of library, armory, or kitchen'
          end
        end

        context 'when there is a library and a kitchen' do
          it 'adds an error' do
            property.has_library = true
            property.has_kitchen = true
            validate
            expect(property.errors[:east_wing]).to include 'can only have one of library, armory, or kitchen'
          end
        end

        context 'when there is an armory and a kitchen' do
          it 'adds an error' do
            property.has_armory = true
            property.has_kitchen = true
            validate
            expect(property.errors[:east_wing]).to include 'can only have one of library, armory, or kitchen'
          end
        end

        context 'when there are all three' do
          it 'adds an error' do
            property.has_library = true
            property.has_armory = true
            property.has_kitchen = true
            validate
            expect(property.errors[:east_wing]).to include 'can only have one of library, armory, or kitchen'
          end
        end
      end

      context 'when a single east-wing room is specified' do
        context 'when there is a library' do
          it "doesn't add an error" do
            property.has_library = true
            validate
            expect(property.errors[:east_wing]).to be_blank
          end
        end

        context 'when there is an armory' do
          it "doesn't add an error" do
            property.has_armory = true
            validate
            expect(property.errors[:east_wing]).to be_blank
          end
        end

        context 'when there is a kitchen' do
          it "doesn't add an error" do
            property.has_kitchen = true
            validate
            expect(property.errors[:east_wing]).to be_blank
          end
        end
      end

      context 'when there are no east-wing rooms' do
        it "doesn't add an error" do
          validate
          expect(property.errors[:east_wing]).to be_blank
        end
      end
    end
  end
end

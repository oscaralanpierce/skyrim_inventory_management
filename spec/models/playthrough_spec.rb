# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Playthrough, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    describe 'name' do
      describe 'uniqueness' do
        let(:playthrough) { build(:playthrough, name: 'My playthrough', user:) }

        it 'is unique per user' do
          create(:playthrough, name: 'My playthrough', user:)

          playthrough.validate
          expect(playthrough.errors[:name]).to include('must be unique')
        end

        it "doesn't have to be unique across all users" do
          create(:playthrough, name: 'My playthrough')
          expect(playthrough).to be_valid
        end
      end

      describe 'format' do
        it 'only contains alphanumeric characters, spaces, commas, hyphens, and apostrophes', :aggregate_failures do
          invalid_playthrough = build(:playthrough, name: "#\t&\n^")

          invalid_playthrough.validate
          expect(invalid_playthrough.errors[:name]).to include("can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')")

          valid_playthrough = build(:playthrough, name: "bA1 ,-'")
          expect(valid_playthrough).to be_valid
        end
      end
    end
  end

  describe 'scopes' do
    describe '::index_order' do
      subject(:index_order) { described_class.index_order }

      let!(:playthrough1) { create(:playthrough) }
      let!(:playthrough2) { create(:playthrough) }
      let!(:playthrough3) { create(:playthrough) }

      before do
        # make sure the last updated playthrough is first, not the last created
        playthrough2.update!(name: 'New Name')
      end

      it 'returns the playthroughs in descending order of updated_at' do
        expect(index_order.to_a).to eq([playthrough2, playthrough3, playthrough1])
      end
    end
  end

  describe '#destroy!' do
    let!(:playthrough) { create(:playthrough_with_everything, user:) }

    # This is a regression test. playthroughs were failing to be destroyed because, when
    # destroying their wish lists, the aggregate list wasn't necessarily
    # destroyed last. The Aggregatable concern prevents aggregate lists from being
    # destroyed if they have child lists. However, since the index_order scope puts
    # the aggregate list first, it is the first list the playthrough attempts to destroy.
    # We had to implement another `before_destroy` callback to ensure this behaviour
    # didn't make it impossible to destroy a playthrough with Aggregatable child models.

    it "destroys all the playthrough's wish lists" do
      expect { playthrough.destroy! }
        .to change(WishList, :count).from(3).to(0)
    end

    it "destroys all the playthrough's wish list items" do
      expect { playthrough.destroy! }
        .to change(WishListItem, :count).from(8).to(0)
    end

    it "destroys all the playthrough's inventory lists" do
      expect { playthrough.destroy! }
        .to change(InventoryList, :count).from(3).to(0)
    end

    it "destroys all the playthrough's inventory list items" do
      expect { playthrough.destroy! }
        .to change(InventoryItem, :count).from(8).to(0)
    end
  end

  describe 'name transformations' do
    context 'when the user has set a name' do
      subject(:name) { user.playthroughs.create!(name: 'Skyrim, Baby').name }

      it 'keeps the name the user has set' do
        expect(name).to eq('Skyrim, Baby')
      end
    end

    context 'when the name has a default value' do
      subject(:name) { user.playthroughs.create!.name }

      context 'when the user has all default-named playthroughs' do
        before do
          create_list(:playthrough, 2, name: nil, user:)
        end

        it 'sets the title based on the highest numbered default title' do
          expect(name).to eq('My Playthrough 3')
        end
      end

      context 'when the user has differently titled playthroughs' do
        before do
          create(:playthrough, user:, name: nil)
          create(:playthrough, user:, name: 'New playthrough')
          create(:playthrough, user:, name: nil)
        end

        it 'uses the next highest number in default-named playthroughs' do
          expect(name).to eq('My Playthrough 3')
        end
      end

      context 'when the user has a playthrough with a similar name' do
        before do
          create(:playthrough, user:, name: 'This playthrough is Called My playthrough 4')
          create_list(:playthrough, 2, user:, name: nil)
        end

        it 'sets the name based on the highest numbered playthrough called "My playthrough N"' do
          expect(name).to eq('My Playthrough 3')
        end
      end

      context 'when there is a playthrough called "My Playthrough <non-integer>"' do
        before do
          create(:playthrough, user:, name: 'My Playthrough Is the Best Playthrough')
          create_list(:playthrough, 2, user:, name: nil)
        end

        it 'sets the name based on the highest numbered playthrough called "My Playthrough N"' do
          expect(name).to eq('My Playthrough 3')
        end
      end

      context 'when there is a playthrough called "My Playthrough <negative integer>"' do
        before do
          create(:playthrough, user:, name: 'My Playthrough -4')
        end

        it 'ignores the playthrough name with the negative integer' do
          expect(name).to eq('My Playthrough 1')
        end
      end
    end

    context 'when the request includes sloppy data' do
      it 'uses intelligent title capitalisation' do
        playthrough = create(:playthrough, name: 'loRd oF tHe rIngS')
        expect(playthrough.name).to eq('Lord of the Rings')
      end

      it 'strips trailing and leading whitespace' do
        playthrough = create(:playthrough, name: "  lord oF tHE rIngS\n\t")
        expect(playthrough.name).to eq('Lord of the Rings')
      end
    end
  end

  describe '#aggregate_wish_list' do
    subject(:aggregate_wish_list) { playthrough.aggregate_wish_list }

    let(:playthrough) { create(:playthrough) }
    let!(:aggregate_list) { create(:aggregate_wish_list, playthrough:) }

    before do
      create_list(:wish_list, 2, playthrough:)
    end

    it "returns that playthrough's aggregate wish list" do
      expect(aggregate_wish_list).to eq(aggregate_list)
    end
  end

  describe '#aggregate_inventory_list' do
    subject(:aggregate_inventory_list) { playthrough.aggregate_inventory_list }

    let(:playthrough) { create(:playthrough) }
    let!(:aggregate_list) { create(:aggregate_inventory_list, playthrough:) }

    before do
      create_list(:inventory_list, 2, playthrough:)
    end

    it "returns that playthrough's aggregate inventory list" do
      expect(aggregate_inventory_list).to eq(aggregate_list)
    end
  end

  describe '#wish_list_items' do
    subject(:wish_list_items) { playthrough.wish_list_items.to_a.sort }

    let(:playthrough) { create(:playthrough, user:) }

    before do
      create_list(:wish_list_with_list_items, 2, playthrough:)
      create(:playthrough_with_wish_lists_and_items, user:) # one that shouldn't be included
    end

    it 'returns all list items belonging to the playthrough' do
      items = playthrough.wish_lists.map {|list| list.list_items.to_a }
      items.flatten!
      items.sort!

      expect(wish_list_items).to eq(items)
    end
  end

  describe '#inventory_items' do
    subject(:inventory_items) { playthrough.inventory_items.to_a.sort }

    let(:playthrough) { create(:playthrough, user:) }

    before do
      create_list(:inventory_list_with_list_items, 2, playthrough:)
      create(:playthrough_with_inventory_lists_and_items, user:) # one that shouldn't be included
    end

    it 'returns all list items belonging to the playthrough' do
      items = playthrough.inventory_lists.map {|list| list.list_items.to_a }
      items.flatten!
      items.sort!

      expect(inventory_items).to eq(items)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Game, type: :model do
  let(:user) { create(:user) }

  describe 'validations' do
    describe 'name' do
      describe 'uniqueness' do
        let(:game) { build(:game, name: 'My Game', user:) }

        it 'is unique per user' do
          create(:game, name: 'My Game', user:)

          game.validate
          expect(game.errors[:name]).to include 'must be unique'
        end

        it "doesn't have to be unique across all users" do
          create(:game, name: 'My Game')
          expect(game).to be_valid
        end
      end

      describe 'format' do
        it 'only contains alphanumeric characters, spaces, commas, hyphens, and apostrophes', :aggregate_failures do
          invalid_game = build(:game, name: "#\t&\n^")

          invalid_game.validate
          expect(invalid_game.errors[:name]).to include "can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')"

          valid_game = build(:game, name: "bA1 ,-'")
          expect(valid_game).to be_valid
        end
      end
    end
  end

  describe 'scopes' do
    describe '::index_order' do
      subject(:index_order) { described_class.index_order }

      let!(:game1) { create(:game) }
      let!(:game2) { create(:game) }
      let!(:game3) { create(:game) }

      before do
        # make sure the last updated game is first, not the last created
        game2.update!(name: 'New Name')
      end

      it 'returns the games in descending order of updated_at' do
        expect(index_order.to_a).to eq([game2, game3, game1])
      end
    end
  end

  describe '#destroy!' do
    let!(:game) { create(:game_with_everything, user:) }

    # This is a regression test. Games were failing to be destroyed because, when
    # destroying their wish lists, the aggregate list wasn't necessarily
    # destroyed last. The Aggregatable concern prevents aggregate lists from being
    # destroyed if they have child lists. However, since the index_order scope puts
    # the aggregate list first, it is the first list the game attempts to destroy.
    # We had to implement another `before_destroy` callback to ensure this behaviour
    # didn't make it impossible to destroy a game with Aggregatable child models.

    it "destroys all the game's wish lists" do
      expect { game.destroy! }
        .to change(WishList, :count).from(3).to(0)
    end

    it "destroys all the game's wish list items" do
      expect { game.destroy! }
        .to change(WishListItem, :count).from(8).to(0)
    end

    it "destroys all the game's inventory lists" do
      expect { game.destroy! }
        .to change(InventoryList, :count).from(3).to(0)
    end

    it "destroys all the game's inventory list items" do
      expect { game.destroy! }
        .to change(InventoryItem, :count).from(8).to(0)
    end
  end

  describe 'name transformations' do
    context 'when the user has set a name' do
      subject(:name) { user.games.create!(name: 'Skyrim, Baby').name }

      it 'keeps the name the user has set' do
        expect(name).to eq 'Skyrim, Baby'
      end
    end

    context 'when the name has a default value' do
      subject(:name) { user.games.create!.name }

      context 'when the user has all default-named games' do
        before { create_list(:game, 2, name: nil, user:) }

        it 'sets the title based on the highest numbered default title' do
          expect(name).to eq 'My Game 3'
        end
      end

      context 'when the user has differently titled games' do
        before do
          create(:game, user:, name: nil)
          create(:game, user:, name: 'New Game')
          create(:game, user:, name: nil)
        end

        it 'uses the next highest number in default-named games' do
          expect(name).to eq 'My Game 3'
        end
      end

      context 'when the user has a game with a similar name' do
        before do
          create(:game, user:, name: 'This Game is Called My Game 4')
          create_list(:game, 2, user:, name: nil)
        end

        it 'sets the name based on the highest numbered game called "My Game N"' do
          expect(name).to eq 'My Game 3'
        end
      end

      context 'when there is a game called "My Game <non-integer>"' do
        before do
          create(:game, user:, name: 'My Game Is the Best Game')
          create_list(:game, 2, user:, name: nil)
        end

        it 'sets the name based on the highest numbered game called "My Game N"' do
          expect(name).to eq 'My Game 3'
        end
      end

      context 'when there is a game called "My Game <negative integer>"' do
        before { create(:game, user:, name: 'My Game -4') }

        it 'ignores the game name with the negative integer' do
          expect(name).to eq 'My Game 1'
        end
      end
    end

    context 'when the request includes sloppy data' do
      it 'uses intelligent title capitalisation' do
        game = create(:game, name: 'loRd oF tHe rIngS')
        expect(game.name).to eq 'Lord of the Rings'
      end

      it 'strips trailing and leading whitespace' do
        game = create(:game, name: "  lord oF tHE rIngS\n\t")
        expect(game.name).to eq 'Lord of the Rings'
      end
    end
  end

  describe '#aggregate_wish_list' do
    subject(:aggregate_wish_list) { game.aggregate_wish_list }

    let(:game) { create(:game) }
    let!(:aggregate_list) { create(:aggregate_wish_list, game:) }

    before { create_list(:wish_list, 2, game:) }

    it "returns that game's aggregate wish list" do
      expect(aggregate_wish_list).to eq aggregate_list
    end
  end

  describe '#aggregate_inventory_list' do
    subject(:aggregate_inventory_list) { game.aggregate_inventory_list }

    let(:game) { create(:game) }
    let!(:aggregate_list) { create(:aggregate_inventory_list, game:) }

    before { create_list(:inventory_list, 2, game:) }

    it "returns that game's aggregate inventory list" do
      expect(aggregate_inventory_list).to eq aggregate_list
    end
  end

  describe '#wish_list_items' do
    subject(:wish_list_items) { game.wish_list_items.to_a.sort }

    let(:game) { create(:game, user:) }

    before do
      create_list(:wish_list_with_list_items, 2, game:)
      create(:game_with_wish_lists_and_items, user:) # one that shouldn't be included
    end

    it 'returns all list items belonging to the game' do
      items = game.wish_lists.map {|list| list.list_items.to_a }
      items.flatten!
      items.sort!

      expect(wish_list_items).to eq items
    end
  end

  describe '#inventory_items' do
    subject(:inventory_items) { game.inventory_items.to_a.sort }

    let(:game) { create(:game, user:) }

    before do
      create_list(:inventory_list_with_list_items, 2, game:)
      create(:game_with_inventory_lists_and_items, user:) # one that shouldn't be included
    end

    it 'returns all list items belonging to the game' do
      items = game.inventory_lists.map {|list| list.list_items.to_a }
      items.flatten!
      items.sort!

      expect(inventory_items).to eq items
    end
  end
end

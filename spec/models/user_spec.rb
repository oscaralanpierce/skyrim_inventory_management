# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  describe '::create_or_update_for_google' do
    subject(:create_or_update) { described_class.create_or_update_for_google(payload) }

    let(:payload) do
      {
        'localId' => 'foobar',
        'email' => 'jane.doe@gmail.com',
        'displayName' => 'Jane Doe',
        'photoUrl' => 'https://example.com/user_images/89',
      }
    end

    context 'when a user with that uid does not exist' do
      it 'creates a user' do
        expect { create_or_update }
          .to change(described_class, :count).from(0).to(1)
      end

      it 'sets the attributes' do
        create_or_update
        expect(described_class.last.attributes).to include(
          'uid' => 'foobar',
          'email' => 'jane.doe@gmail.com',
          'display_name' => 'Jane Doe',
          'photo_url' => 'https://example.com/user_images/89',
        )
      end
    end

    context 'when there is already a user with that uid' do
      let!(:user) { create(:user, uid: 'foobar', email: 'jane.doe@gmail.com', display_name: 'Jane Doe', photo_url: nil) }

      it 'does not create a new user' do
        expect { create_or_update }
          .not_to change(described_class, :count)
      end

      it 'updates the attributes' do
        create_or_update
        expect(user.reload.photo_url).to eq('https://example.com/user_images/89')
      end
    end
  end

  describe '#wish_lists' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    let(:game1) { create(:game, user: user1) }
    let(:game2) { create(:game, user: user1) }
    let(:game3) { create(:game_with_wish_lists, user: user2) }

    let!(:wish_list1) { create(:aggregate_wish_list, game: game1) }
    let!(:wish_list2) { create(:wish_list, game: game1) }
    let!(:wish_list3) { create(:aggregate_wish_list, game: game2) }
    let!(:wish_list4) { create(:wish_list, game: game2) }

    it "returns all the wish lists for the user's games" do
      expect(user1.wish_lists).to eq([
        wish_list4,
        wish_list3,
        wish_list2,
        wish_list1,
      ])
    end
  end

  describe '#inventory_lists' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    let(:game1) { create(:game, user: user1) }
    let(:game2) { create(:game, user: user1) }
    let(:game3) { create(:game_with_inventory_lists, user: user2) }

    let!(:inventory_list1) { create(:aggregate_inventory_list, game: game1) }
    let!(:inventory_list2) { create(:inventory_list, game: game1) }
    let!(:inventory_list3) { create(:aggregate_inventory_list, game: game2) }
    let!(:inventory_list4) { create(:inventory_list, game: game2) }

    it "returns all the inventory lists for the user's games" do
      expect(user1.inventory_lists).to eq([
        inventory_list4,
        inventory_list3,
        inventory_list2,
        inventory_list1,
      ])
    end
  end

  describe '#wish_list_items' do
    subject(:wish_list_items) { user1.wish_list_items.to_a.sort }

    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    let(:game1) { create(:game_with_wish_lists_and_items, user: user1) }
    let(:game2) { create(:game_with_wish_lists_and_items, user: user1) }
    let(:game3) { create(:game_with_wish_lists_and_items, user: user2) }

    it 'includes the wish list items belonging to that user' do
      user1_list_items = game1.wish_list_items.to_a + game2.wish_list_items.to_a
      user1_list_items.sort!

      expect(wish_list_items).to eq(user1_list_items)
    end
  end

  describe '#inventory_items' do
    subject(:inventory_items) { user1.inventory_items.to_a.sort }

    let(:user1) { create(:user) }
    let(:user2) { create(:user) }

    let(:game1) { create(:game_with_inventory_lists_and_items, user: user1) }
    let(:game2) { create(:game_with_inventory_lists_and_items, user: user1) }
    let(:game3) { create(:game_with_inventory_lists_and_items, user: user2) }

    it 'includes the inventory list items belonging to that user' do
      user1_list_items = game1.inventory_items.to_a + game2.inventory_items.to_a
      user1_list_items.sort!

      expect(inventory_items).to eq(user1_list_items)
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WishListItem, type: :model do
  let!(:game) { create(:game) }
  let(:aggregate_list) { create(:aggregate_wish_list, game:) }
  let(:wish_list) { create(:wish_list, game:, aggregate_list:) }

  describe 'validation' do
    let(:item) { build(:wish_list_item) }

    it 'is invalid with a quantity less than 1' do
      item.quantity = 0
      item.validate
      expect(item.errors[:quantity]).to include('must be greater than 0')
    end

    it 'is invalid with a decimal quantity' do
      item.quantity = 1.5
      item.validate
      expect(item.errors[:quantity]).to include('must be an integer')
    end

    it 'is invalid with a non-numeric quantity' do
      item.quantity = 'foo'
      item.validate
      expect(item.errors[:quantity]).to include('is not a number')
    end

    it 'is invalid with a negative unit weight' do
      item.unit_weight = -1
      item.validate
      expect(item.errors[:unit_weight]).to include('must be greater than or equal to 0')
    end

    it 'is invalid with a non-numeric unit weight' do
      item.unit_weight = 'foo'
      item.validate
      expect(item.errors[:unit_weight]).to include('is not a number')
    end

    it 'is valid with a decimal unit weight' do
      item.unit_weight = 0.1
      expect(item).to be_valid
    end

    it 'is valid with notes if not on an aggregate list' do
      item.notes = 'hello world'
      expect(item).to be_valid
    end

    it 'is invalid with notes if on an aggregate list' do
      item.list = aggregate_list
      item.notes = 'hello world'
      item.validate
      expect(item.errors[:notes]).to include('cannot be present on an aggregate list item')
    end
  end

  describe 'delegation' do
    let(:list_item) { create(:wish_list_item, list: wish_list) }

    describe '#game' do
      it 'returns the game its WishList belongs to' do
        expect(list_item.game).to eq game
      end
    end

    describe '#user' do
      it 'returns the user its game belongs to' do
        expect(list_item.user).to eq game.user
      end
    end
  end

  describe 'scopes' do
    describe '::index_order' do
      let!(:list_item1) { create(:wish_list_item, list:) }
      let!(:list_item2) { create(:wish_list_item, list:) }
      let!(:list_item3) { create(:wish_list_item, list:) }

      let(:list) { create(:wish_list, game:) }

      before { list_item2.update!(quantity: 3) }

      it 'returns the list items in descending chronological order by updated_at' do
        expect(list.list_items.index_order.to_a).to eq([list_item2, list_item3, list_item1])
      end
    end

    describe '::belonging_to_game' do
      let!(:list1) { create(:wish_list_with_list_items, game:, aggregate_list:) }
      let!(:list2) { create(:wish_list_with_list_items, game:, aggregate_list:) }
      let!(:list3) { create(:wish_list_with_list_items, game:, aggregate_list:) }

      before do
        # There should be some that don't belong to the game to make sure they
        # don't also get included
        create(:wish_list_with_list_items)
      end

      it 'returns all list items from all the lists for the given game' do
        # We don't actually care what order these are in since we currently only use this
        # scope to determine whether a given item belongs to a particular game
        items = [list1.list_items.to_a, list2.list_items.to_a, list3.list_items.to_a].flatten!

        expect(described_class.belonging_to_game(game).to_a.sort).to eq(items.sort)
      end
    end

    describe '::belonging_to_user' do
      # We're going to sort these because we don't actually care what order they're in
      subject(:belonging_to_user) { described_class.belonging_to_user(user).to_a.sort }

      let(:user) { game.user }

      before do
        create(:wish_list_with_list_items, game:, aggregate_list:)
        create(:game_with_wish_lists_and_items, user:)
        create(:game_with_wish_lists_and_items, user:)
        create(:wish_list_with_list_items) # one from a different user
      end

      it 'returns all the list items belonging to the user', :aggregate_failures do
        all_items = []
        user.wish_lists.each {|list| all_items << list.list_items }
        all_items.flatten!.sort!

        expect(belonging_to_user).to eq all_items
      end
    end
  end

  describe '::combine_or_create!' do
    context 'when there is an existing item on the same list with the same (case-insensitive) description' do
      subject(:combine_or_create) { described_class.combine_or_create!(description: 'existing item', quantity: 1, list: wish_list, notes: notes2) }

      let!(:existing_item) { create(:wish_list_item, description: 'ExIsTiNg ItEm', quantity: 2, unit_weight: 0.3, list: wish_list, notes: notes1) }

      let(:notes1) { 'notes 1' }
      let(:notes2) { 'notes 2' }

      it "doesn't create a new list item" do
        expect { combine_or_create }
          .not_to change(wish_list.list_items, :count)
      end

      it 'adds the quantity to the existing item' do
        combine_or_create
        expect(existing_item.reload.quantity).to eq 3
      end

      it 'concatenates the notes for the two items' do
        combine_or_create
        expect(existing_item.reload.notes).to eq "#{notes1} -- #{notes2}"
      end

      context "when the new item doesn't have a unit_weight" do
        it 'leaves the unit_weight as-is' do
          combine_or_create
          expect(existing_item.reload.unit_weight).to eq 0.3
        end
      end

      context 'when the new item has a unit_weight' do
        subject(:combine_or_create) { described_class.combine_or_create!(description: 'existing item', quantity: 1, list: wish_list, unit_weight: 0.2, notes: notes2) }

        it 'uses the unit_weight from the new item' do
          combine_or_create
          expect(existing_item.reload.unit_weight).to eq 0.2
        end
      end

      context 'when the list is an aggregate list' do
        let(:wish_list) { aggregate_list }
        let(:notes1) { nil }
        let(:notes2) { 'notes 2' }

        it 'leaves the notes as nil' do
          combine_or_create
          expect(wish_list.list_items.last.reload.notes).to be_nil
        end
      end
    end

    context 'when there is an existing item on a different list with the same (case-insensitive) description' do
      subject(:combine_or_create) { described_class.combine_or_create!(description: 'New Item', quantity: 1, list: wish_list, unit_weight:) }

      let!(:other_item) { create(:wish_list_item, description: 'New Item', list: other_list, unit_weight: 1) }

      let(:other_list) { create(:wish_list, game:, aggregate_list:) }

      before { aggregate_list.add_item_from_child_list(other_item) }

      context 'when unit_weight is nil' do
        let(:unit_weight) { nil }

        it 'sets the unit weight to that of the existing item' do
          expect(combine_or_create.unit_weight).to eq 1
        end
      end
    end
  end

  describe '::combine_or_new' do
    context 'when there is an existing item on the same list with the same (case-insensitive) description' do
      subject(:combine_or_new) { described_class.combine_or_new(description: 'existing item', quantity: 1, list: wish_list, notes: 'notes 2') }

      let!(:existing_item) { create(:wish_list_item, description: 'ExIsTiNg ItEm', quantity: 2, unit_weight: 0.3, list: wish_list, notes: 'notes 1') }

      before { allow(described_class).to receive(:new) }

      it "doesn't instantiate a new item" do
        combine_or_new
        expect(described_class).not_to have_received(:new)
      end

      it 'returns the existing item with the quantity updated', :aggregate_failures do
        expect(combine_or_new).to eq existing_item
        expect(combine_or_new.quantity).to eq 3
      end

      it 'concatenates the notes for the two items', :aggregate_failures do
        expect(combine_or_new).to eq existing_item
        expect(combine_or_new.notes).to eq 'notes 1 -- notes 2'
      end

      context "when the new item doesn't have a unit_weight" do
        it 'leaves the unit_weight as-is' do
          expect(combine_or_new.unit_weight).to eq 0.3
        end
      end

      context 'when the new item has a unit_weight' do
        subject(:combine_or_new) { described_class.combine_or_new(description: 'existing item', quantity: 1, unit_weight: 0.2, list: wish_list, notes: 'notes 2') }

        it 'updates the unit_weight' do
          expect(combine_or_new.unit_weight).to eq 0.2
        end
      end
    end

    context 'when there is not an existing item on the same list with that description' do
      subject(:combine_or_new) { described_class.combine_or_new(description: 'new item', quantity: 1, list: wish_list) }

      before { allow(described_class).to receive(:new).and_call_original }

      it 'instantiates a new wish list item' do
        combine_or_new
        expect(described_class).to have_received(:new)
      end

      it "doesn't save the wish list item yet" do
        expect { combine_or_new }
          .not_to change(wish_list.list_items, :count)
      end

      context 'when unit weight is nil and there are matching items on other lists' do
        let!(:other_list) { create(:wish_list, game:, aggregate_list:) }
        let!(:other_item) { create(:wish_list_item, description: 'new item', list: other_list, unit_weight: 1) }

        before { aggregate_list.add_item_from_child_list(other_item) }

        it "sets the new item's unit weight to match the existing items" do
          expect(combine_or_new.unit_weight).to eq 1
        end
      end
    end

    context 'when the new item is on an aggregate list' do
      subject(:combine_or_new) { described_class.combine_or_new(description: 'new item', quantity: 3, list: aggregate_list, notes: 'foobar') }

      it "doesn't set a 'notes' value on the aggregate list item" do
        expect(combine_or_new.notes).to be_nil
      end
    end

    context 'when the existing item is on an aggregate list' do
      subject(:combine_or_new) { described_class.combine_or_new(description: 'new item', quantity: 3, list: aggregate_list, notes: 'foobar') }

      before { aggregate_list.list_items.create!(description: 'new item', quantity: 1) }

      it "doesn't set a 'notes' value on the aggregate list item", :aggregate_failures do
        new_item = combine_or_new
        expect(new_item.quantity).to eq 4
        expect(new_item.notes).to be_nil
      end
    end
  end

  describe '#update!' do
    let!(:list_item) { create(:wish_list_item, quantity: 1, list: wish_list) }

    context 'when updating quantity' do
      subject(:update_item) { list_item.update!(quantity: 4) }

      it 'updates as normal' do
        expect { update_item }
          .to change(list_item, :quantity).from(1).to(4)
      end
    end

    context 'when updating description' do
      subject(:update_item) { list_item.update!(description: 'Something else') }

      it 'raises an error' do
        expect { update_item }
          .to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end

  describe 'notes field' do
    it 'cleans up leading and trailing dashes or whitespace' do
      wish_list_item = build(:wish_list_item, notes: ' -- some notes --')
      expect { wish_list_item.save }
        .to change(wish_list_item, :notes).to('some notes')
    end

    it 'saves as nil if it consists only of dashes' do
      wish_list_item = build(:wish_list_item, notes: '--')
      expect { wish_list_item.save }
        .to change(wish_list_item, :notes).to(nil)
    end
  end
end

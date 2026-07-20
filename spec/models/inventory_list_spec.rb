# frozen_string_literal: true

require 'rails_helper'

RSpec.describe InventoryList, type: :model do
  describe 'scopes' do
    describe '::index_order' do
      subject(:index_order) { playthrough.inventory_lists.index_order.to_a }

      let!(:playthrough) { create(:playthrough) }
      let!(:aggregate_list) { create(:aggregate_inventory_list, playthrough:) }
      let!(:inventory_list1) { create(:inventory_list, playthrough:) }
      let!(:inventory_list2) { create(:inventory_list, playthrough:) }
      let!(:inventory_list3) { create(:inventory_list, playthrough:) }

      before do
        inventory_list2.update!(title: 'Windstad Manor')
      end

      it 'is in reverse chronological order by updated_at with aggregate before anything' do
        expect(index_order).to eq([aggregate_list, inventory_list2, inventory_list3, inventory_list1])
      end
    end

    # Aggregatable
    describe '::includes_items' do
      subject(:includes_items) { playthrough.inventory_lists.includes_items }

      let!(:playthrough) { create(:playthrough) }
      let!(:aggregate_list) { create(:aggregate_inventory_list, playthrough:) }
      let!(:lists) { create_list(:inventory_list_with_list_items, 2, playthrough:) }

      it 'includes the inventory list items' do
        expect(includes_items).to eq(playthrough.inventory_lists.includes(:list_items))
      end
    end

    # Aggregatable
    describe '::aggregates_first' do
      subject(:aggregate_first) { playthrough.inventory_lists.aggregate_first.to_a }

      let!(:playthrough) { create(:playthrough) }
      let!(:aggregate_list) { create(:aggregate_inventory_list, playthrough:) }
      let!(:inventory_list) { create(:inventory_list, playthrough:) }

      it 'returns the inventory lists with the aggregate list first' do
        expect(aggregate_first).to eq([aggregate_list, inventory_list])
      end
    end

    describe '::belongs_to_user' do
      let(:user) { create(:user) }
      let!(:playthrough1) { create(:playthrough_with_inventory_lists, user:) }
      let!(:playthrough2) { create(:playthrough_with_inventory_lists, user:) }
      let!(:playthrough3) { create(:playthrough_with_inventory_lists, user:) }

      it "returns all the inventory lists from all the user's playthroughs" do
        # These are going to be rearranged in the output since playthrough.inventory_lists
        # comes back aggregate list first and the scope will return them in descending
        # updated_at order. There was no easy programmatic way to rearrange them so
        # I just have to pull them all out and reorder them in the expectation.
        agg_list1, playthrough1_list1, playthrough1_list2 = playthrough1.inventory_lists.to_a
        agg_list2, playthrough2_list1, playthrough2_list2 = playthrough2.inventory_lists.to_a
        agg_list3, playthrough3_list1, playthrough3_list2 = playthrough3.inventory_lists.to_a

        expect(described_class.belonging_to_user(user).to_a).to eq([
          playthrough3_list1,
          playthrough3_list2,
          agg_list3,
          playthrough2_list1,
          playthrough2_list2,
          agg_list2,
          playthrough1_list1,
          playthrough1_list2,
          agg_list1,
        ])
      end
    end
  end

  describe 'validations' do
    # Aggregatable
    describe 'aggregate lists' do
      context 'when there are no aggregate lists' do
        let(:playthrough) { create(:playthrough) }
        let(:aggregate_list) { build(:aggregate_inventory_list, playthrough:) }

        it 'is valid' do
          expect(aggregate_list).to be_valid
        end
      end

      context 'when there is an existing aggregate list belonging to another playthrough' do
        let(:playthrough) { create(:playthrough) }
        let(:aggregate_list) { build(:aggregate_inventory_list, playthrough:) }

        before do
          other_playthrough = create(:playthrough, user: playthrough.user)
          create(:aggregate_inventory_list, playthrough: other_playthrough)
        end

        it 'is valid' do
          expect(aggregate_list).to be_valid
        end
      end

      context 'when the user already has an aggregate list' do
        let(:playthrough) { create(:playthrough) }
        let(:aggregate_list) { build(:aggregate_inventory_list, playthrough:) }

        before do
          create(:aggregate_inventory_list, playthrough:)
        end

        it 'is invalid', :aggregate_failures do
          expect(aggregate_list).not_to be_valid
          expect(aggregate_list.errors[:aggregate]).to eq(['can only be one list per playthrough'])
        end
      end
    end

    describe 'title validations' do
      # Aggregatable
      context 'when the title is "all items"' do
        it 'is allowed for an aggregate list' do
          list = build(:aggregate_inventory_list, title: 'All Items')
          expect(list).to be_valid
        end

        it 'is not allowed for a regular list', :aggregate_failures do
          list = build(:inventory_list, title: 'all items')
          expect(list).not_to be_valid
          expect(list.errors[:title]).to include('cannot be "All Items"')
        end
      end

      context 'when the title contains "all items" as well as other characters' do
        it 'is valid' do
          list = build(:inventory_list, title: 'aLL iTems the seQUel')

          expect(list).to be_valid
        end
      end

      describe 'allowed characters' do
        it 'allows alphanumeric characters, spaces, commas, apostrophes, and hyphens' do
          list = build(:inventory_list, title: "aB 61 ,'-")

          expect(list).to be_valid
        end

        it "doesn't allow newlines", :aggregate_failures do
          list = build(:inventory_list, title: "My\nList 1  ")

          list.validate
          expect(list.errors[:title]).to include("can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')")
        end

        it "doesn't allow other non-space whitespace", :aggregate_failures do
          list = build(:inventory_list, title: "My\tList 1")

          list.validate
          expect(list.errors[:title]).to include("can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')")
        end

        it "doesn't allow special characters", :aggregate_failures do
          list = build(:inventory_list, title: 'My^List&1')

          list.validate
          expect(list.errors[:title]).to include("can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')")
        end

        # Leading and trailing whitespace characters will be stripped anyway so no need to validate
        it 'ignores leading or trailing whitespace characters' do
          list = build(:inventory_list, title: "My List 1\n\t")

          expect(list).to be_valid
        end
      end
    end
  end

  # Aggregatable
  describe '#aggregate_list' do
    let!(:aggregate_list) { create(:aggregate_inventory_list) }
    let(:inventory_list) { create(:inventory_list, playthrough: aggregate_list.playthrough) }

    it 'returns the aggregate list that tracks it' do
      expect(inventory_list.aggregate_list).to eq(aggregate_list)
    end
  end

  describe 'title transformations' do
    describe 'setting a default title' do
      let(:playthrough) { create(:playthrough) }

      # I don't use FactoryBot to create the models in the subject blocks because
      # it sets values for certain attributes and I don't want those to get in the way.
      context 'when the list is not an aggregate list' do
        context 'when the user has set a title' do
          subject(:title) { playthrough.inventory_lists.create!(title: 'Heljarchen Hall').title }

          let(:playthrough) { create(:playthrough) }

          it 'keeps the title the user has set' do
            expect(title).to eq('Heljarchen Hall')
          end
        end

        context 'when the user has not set a title' do
          subject(:title) { playthrough.inventory_lists.create!.title }

          context 'when the playthrough has all default-titled regular lists' do
            before do
              # Create lists for a different playthrough to make sure the name of this playthrough's
              # list isn't affected by them
              create_list(:inventory_list, 2, title: nil)
              create_list(:inventory_list, 2, title: nil, playthrough:)
            end

            it 'sets the title based on the highest numbered default title' do
              expect(title).to eq('My List 3')
            end
          end

          context 'when the playthrough has differently titled regular lists' do
            before do
              create(:inventory_list, title: nil)
              create(:inventory_list, playthrough:, title: nil)
              create(:inventory_list, playthrough:, title: 'Windstad Manor')
              create(:inventory_list, playthrough:, title: nil)
            end

            it 'uses the next highest number in default lists' do
              expect(title).to eq('My List 3')
            end
          end

          context 'when the playthrough has an inventory list with a similar title' do
            before do
              create(:inventory_list, playthrough:, title: 'This List is Called My List 4')
              create_list(:inventory_list, 2, playthrough:, title: nil)
            end

            it 'sets the title based on the highest numbered list called "My List N"' do
              expect(title).to eq('My List 3')
            end
          end

          context 'when there is an inventory list called "My List <non-integer>"' do
            before do
              create(:inventory_list, playthrough:, title: 'My List Is the Best List')
              create_list(:inventory_list, 2, playthrough:, title: nil)
            end

            it 'sets the title based on the highest numbered list called "My List N"' do
              expect(title).to eq('My List 3')
            end
          end

          context 'when there is an inventory list called "My List <negative integer>"' do
            before do
              create(:inventory_list, playthrough:, title: 'My List -4')
            end

            it 'ignores the list title with the negative integer' do
              expect(title).to eq('My List 1')
            end
          end
        end
      end

      # Aggregatable
      context 'when the list is an aggregate list' do
        context 'when the user has set a title' do
          subject(:title) { playthrough.inventory_lists.create!(aggregate: true, title: 'Something other than all items').title }

          it 'overrides the title the user has set' do
            expect(title).to eq('All Items')
          end
        end

        context 'when the user has not set a title' do
          subject(:title) { playthrough.inventory_lists.create!(aggregate: true).title }

          it 'sets the title to "All Items"' do
            expect(title).to eq('All Items')
          end
        end
      end
    end

    context 'when the request includes sloppy data' do
      it 'uses intelligent title capitalisation' do
        list = create(:inventory_list, title: 'lord oF thE rIngs')
        expect(list.title).to eq('Lord of the Rings')
      end

      it 'strips trailing and leading whitespace' do
        list = create(:inventory_list, title: " lord oF tHe RiNgs\n")
        expect(list.title).to eq('Lord of the Rings')
      end
    end
  end

  describe 'associations' do
    subject(:items) { inventory_list.list_items }

    let!(:aggregate_list) { create(:aggregate_inventory_list) }
    let(:inventory_list) { create(:inventory_list, playthrough: aggregate_list.playthrough, aggregate_list_id: aggregate_list.id) }
    let!(:item1) { create(:inventory_item, list: inventory_list) }
    let!(:item2) { create(:inventory_item, list: inventory_list) }
    let!(:item3) { create(:inventory_item, list: inventory_list) }

    before do
      item2.update!(quantity: 2)
    end

    it 'keeps child models in descending order of updated_at' do
      expect(inventory_list.list_items.to_a).to eq([item2, item3, item1])
    end
  end

  # Aggregatable
  describe 'before_destroy hook' do
    context 'when trying to destroy the aggregate list' do
      subject(:destroy_list) { inventory_list.destroy! }

      let(:inventory_list) { create(:aggregate_inventory_list) }

      context 'when the playthrough has regular lists' do
        before do
          create(:inventory_list, playthrough: inventory_list.playthrough, aggregate_list: inventory_list)
        end

        it 'raises an error and does not destroy the list' do
          expect { destroy_list }
            .to raise_error(ActiveRecord::RecordNotDestroyed)
        end
      end

      context 'when the playthrough has no regular lists' do
        it 'destroys the aggregate list' do
          expect { destroy_list }
            .to change(inventory_list.playthrough.inventory_lists, :count).from(1).to(0)
        end
      end
    end
  end

  # Aggregatable
  describe 'after_destroy hook' do
    subject(:destroy_list) { inventory_list.destroy! }

    let!(:aggregate_list) { create(:aggregate_inventory_list, playthrough:) }
    let!(:inventory_list) { create(:inventory_list, playthrough:) }
    let(:playthrough) { create(:playthrough) }

    context 'when the playthrough has additional regular lists' do
      before do
        create(:inventory_list, playthrough:)
      end

      it "doesn't destroy the aggregate list" do
        expect { destroy_list }
          .not_to change(playthrough, :aggregate_inventory_list)
      end
    end

    context 'when the playthrough has no additional regular lists' do
      it 'destroys the aggregate list' do
        expect { destroy_list }
          .to change(playthrough.inventory_lists, :count).from(2).to(0)
      end
    end
  end

  describe 'Aggregatable methods' do
    describe '#add_item_from_child_list' do
      subject(:add_item) { aggregate_list.add_item_from_child_list(list_item) }

      let(:aggregate_list) { create(:aggregate_inventory_list) }

      context 'when there is no matching item on the aggregate list' do
        let(:list_item) { create(:inventory_item, unit_weight: 0.5, notes: 'foobar') }

        it 'creates a corresponding item on the aggregate list' do
          expect { add_item }
            .to change(aggregate_list.list_items, :count).from(0).to(1)
        end

        it 'sets the correct attributes' do
          add_item
          expect(aggregate_list.list_items.last.attributes).to include(
            'description' => list_item.description,
            'quantity' => list_item.quantity,
            'unit_weight' => list_item.unit_weight,
            'notes' => nil,
          )
        end
      end

      context 'when there is a matching item on the aggregate list' do
        let(:other_list) { create(:inventory_list, playthrough: aggregate_list.playthrough, aggregate_list:) }

        let!(:item_on_other_list) do
          create(
            :inventory_item,
            description: 'Dwarven metal ingot',
            list: other_list,
            unit_weight: 0.3,
          )
        end

        context 'when the new item has notes' do
          let!(:existing_list_item) { create(:inventory_item, list: aggregate_list, quantity: 3) }

          let(:list_item) do
            create(
              :inventory_item,
              description: existing_list_item.description,
              quantity: 2,
              notes: 'foobar',
            )
          end

          it 'combines the quantities but not the notes values', :aggregate_failures do
            add_item
            expect(existing_list_item.reload.quantity).to eq(5)
            expect(existing_list_item.reload.notes).to be_nil
          end
        end

        context "when the new item doesn't have a unit weight" do
          let!(:existing_list_item) do
            create(
              :inventory_item,
              description: 'Dwarven metal ingot',
              list: aggregate_list,
              unit_weight: 0.3,
            )
          end

          let(:list_item) do
            create(
              :inventory_item,
              description: existing_list_item.description,
              quantity: 2,
              unit_weight: nil,
            )
          end

          it 'leaves the unit weight as-is on the existing item' do
            add_item
            expect(existing_list_item.reload.unit_weight).to eq(0.3)
          end

          it 'leaves the unit weight as-is on the other regular list item' do
            add_item
            expect(item_on_other_list.reload.unit_weight).to eq(0.3)
          end
        end

        context 'when the new item has a unit weight' do
          let!(:existing_list_item) do
            create(
              :inventory_item,
              description: 'Dwarven metal ingot',
              unit_weight: 0.3,
              list: aggregate_list,
            )
          end

          let(:list_item) do
            create(
              :inventory_item,
              description: 'Dwarven metal ingot',
              quantity: 2,
              unit_weight: 0.2,
            )
          end

          it 'updates the unit weight of the existing item' do
            add_item
            expect(existing_list_item.reload.unit_weight).to eq(0.2)
          end

          it 'updates the unit weight of the item on the other list' do
            add_item
            expect(item_on_other_list.reload.unit_weight).to eq(0.2)
          end
        end
      end

      context 'when called on a non-aggregate list' do
        let(:aggregate_list) { create(:inventory_list) }
        let(:list_item) { create(:inventory_item) }

        it 'raises an AggregateListError' do
          expect { add_item }
            .to raise_error(
              Aggregatable::AggregateListError,
              'add_item_from_child_list method only available on aggregate lists',
            )
        end
      end
    end

    describe '#remove_item_from_child_list' do
      subject(:remove_item) { aggregate_list.remove_item_from_child_list(item_attrs) }

      context 'when there is no matching item on the aggregate list' do
        let(:aggregate_list) { create(:aggregate_inventory_list) }
        let(:item_attrs) { { description: 'Necklace', quantity: 3, notes: 'some notes' } }

        it 'raises an error' do
          expect { remove_item }
            .to raise_error(
              Aggregatable::AggregateListError,
              'item passed to remove_item_from_child_list method is not represented on the aggregate list',
            )
        end
      end

      context 'when the quantity is greater than the quantity on the aggregate list' do
        let(:aggregate_list) { create(:aggregate_inventory_list) }
        let(:item_attrs) { { 'description' => 'Necklace', 'quantity' => 3, 'notes' => 'some notes' } }

        before do
          aggregate_list.list_items.create(description: 'Necklace', quantity: 2)
        end

        it 'raises an error' do
          expect { remove_item }
            .to raise_error(Aggregatable::AggregateListError)
        end
      end

      context 'when the quantity is equal to the quantity on the aggregate list' do
        let(:aggregate_list) { create(:aggregate_inventory_list) }
        let(:item_attrs) { { 'description' => 'Necklace', 'quantity' => 3, 'notes' => 'some notes' } }

        before do
          aggregate_list.list_items.create(description: 'Necklace', quantity: 3)
        end

        it 'removes the item from the aggregate list' do
          expect { remove_item }
            .to change(aggregate_list.list_items, :count).from(1).to(0)
        end
      end

      context 'when the quantity is less than the quantity on the aggregate list' do
        let(:aggregate_list) { create(:aggregate_inventory_list) }
        let(:item_attrs) do
          {
            'description' => 'Necklace',
            'quantity' => 3,
            'notes' => 'some notes',
          }
        end

        before do
          create(
            :inventory_item,
            description: 'Necklace',
            quantity: 4,
            list: aggregate_list,
          )
        end

        it 'adjusts the quantity on the aggregate list' do
          remove_item
          expect(aggregate_list.list_items.last.quantity).to eq(1)
        end
      end

      context 'when called on a non-aggregate list' do
        let(:aggregate_list) { create(:inventory_list) }
        let(:item_attrs) { { description: 'Necklace', quantity: 3, notes: 'some notes' } }

        it 'raises an error' do
          expect { remove_item }
            .to raise_error(Aggregatable::AggregateListError)
        end
      end
    end

    describe '#update_item_from_child_list' do
      let(:aggregate_list) { create(:aggregate_inventory_list) }
      let(:description) { 'Corundum ingot' }
      let(:unit_weight) { 1 }

      context 'when adjusting quantity up' do
        subject(:update_item) do
          aggregate_list.update_item_from_child_list(
            description,
            quantity: {
              from: 1,
              to: 3,
            },
          )
        end

        before do
          # upcase the description to test that the comparison is case insensitive
          aggregate_list.list_items.create(description: description.upcase, quantity: 1)
        end

        it 'increases the quantity by the delta' do
          update_item
          expect(aggregate_list.list_items.first.quantity).to eq(3)
        end
      end

      context 'when adjusting quantity down' do
        subject(:update_item) do
          aggregate_list.update_item_from_child_list(
            description,
            quantity: {
              from: 5,
              to: 2,
            },
          )
        end

        before do
          aggregate_list.list_items.create(description:, quantity: 8)
        end

        it 'decreases the quantity by the delta' do
          update_item
          expect(aggregate_list.list_items.first.quantity).to eq(5)
        end
      end

      context 'when the unit weight is being unset' do
        subject(:update_item) do
          aggregate_list.update_item_from_child_list(
            description,
            unit_weight: {
              to: nil,
            },
          )
        end

        let(:other_list) { create(:inventory_list, playthrough: aggregate_list.playthrough, aggregate_list:) }
        let!(:item_on_other_list) do
          create(
            :inventory_item,
            list: other_list,
            description:,
            unit_weight: 1,
          )
        end

        let!(:aggregate_list_item) do
          create(
            :inventory_item,
            list: aggregate_list,
            description:,
            quantity: 3,
            unit_weight: 1,
          )
        end

        it 'updates the aggregate list item unit weight' do
          update_item
          expect(aggregate_list_item.reload.unit_weight).to be_nil
        end

        it 'updates the item on the other list' do
          update_item
          expect(item_on_other_list.reload.unit_weight).to be_nil
        end
      end

      context 'when there is a non-nil unit_weight given' do
        subject(:update_item) do
          aggregate_list.update_item_from_child_list(
            description,
            unit_weight: {
              to: 2,
            },
          )
        end

        let(:other_list) { create(:inventory_list, playthrough: aggregate_list.playthrough, aggregate_list:) }
        let!(:item_on_other_list) { create(:inventory_item, list: other_list, description:, unit_weight: 1) }
        let!(:aggregate_list_item) { create(:inventory_item, list: aggregate_list, description:, quantity: 3, unit_weight: 1) }

        it 'updates the unit_weight on the aggregate list' do
          update_item
          expect(aggregate_list_item.reload.unit_weight).to eq(2)
        end

        it 'updates the other matching list item' do
          update_item
          expect(item_on_other_list.reload.unit_weight).to eq(2)
        end
      end

      context 'when the new quantity is less than 0' do
        subject(:update_item) do
          aggregate_list.update_item_from_child_list(
            description,
            quantity: {
              from: 2,
              to: -1,
            },
          )
        end

        before do
          aggregate_list.list_items.create!(description:, quantity: 4)
        end

        it 'raises an error, even if the aggregate quantity would still be greater than 0' do
          expect { update_item }
            .to raise_error(
              Aggregatable::AggregateListError,
              'Invalid data to update aggregate list item',
            )
        end
      end

      context 'when the given unit_weight is not a number' do
        subject(:update_item) do
          aggregate_list.update_item_from_child_list(
            description,
            unit_weight: {
              to: 'carrot',
            },
          )
        end

        before do
          aggregate_list.list_items.create!(description:)
        end

        it 'raises an error' do
          expect { update_item }
            .to raise_error(
              Aggregatable::AggregateListError,
              'Invalid data to update aggregate list item',
            )
        end
      end

      context 'when the unit_weight value is invalid' do
        subject(:update_item) do
          aggregate_list.update_item_from_child_list(
            description,
            unit_weight: {
              to: -0.3,
            },
          )
        end

        before do
          aggregate_list.list_items.create!(description:, quantity: 1)
        end

        it 'raises an error' do
          expect { update_item }
            .to raise_error(
              Aggregatable::AggregateListError,
              'Invalid data to update aggregate list item',
            )
        end
      end

      context 'when there is no matching item on the aggregate list' do
        subject(:update_item) do
          aggregate_list.update_item_from_child_list(
            description,
            quantity: {
              from: 2,
              to: 4,
            },
          )
        end

        it 'raises an error' do
          expect { update_item }
            .to raise_error(
              Aggregatable::AggregateListError,
              "No aggregate list item with description \"#{description}\"",
            )
        end
      end

      context 'when called on a regular list' do
        subject(:update_item) do
          inventory_list.update_item_from_child_list(
            description,
            unit_weight: 0.3,
          )
        end

        let(:inventory_list) { create(:inventory_list) }

        it 'raises an error' do
          expect { update_item }
            .to raise_error(
              Aggregatable::AggregateListError,
              'update_item_from_child_list method only available on aggregate lists',
            )
        end
      end
    end

    describe '#user' do
      let(:inventory_list) { create(:inventory_list) }

      it 'delegates to the playthrough' do
        expect(inventory_list.user).to eq(inventory_list.playthrough.user)
      end
    end
  end

  describe 'parent model' do
    let(:playthrough) { create(:playthrough) }
    let(:aggregate_list) { create(:aggregate_inventory_list, playthrough:) }

    it 'is invalid without a playthrough' do
      list = described_class.new(aggregate_list:)

      list.validate
      expect(list.errors[:playthrough]).to include('must exist')
    end
  end
end

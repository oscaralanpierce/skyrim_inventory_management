# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Book, type: :model do
  describe 'validations' do
    subject(:validate) { book.validate }

    let(:book) { build(:canonical_book) }

    describe 'title' do
      it "can't be blank" do
        book.title = nil
        validate
        expect(book.errors[:title]).to include("can't be blank")
      end
    end

    describe 'item code' do
      it "can't be blank" do
        book.item_code = nil
        validate
        expect(book.errors[:item_code]).to include("can't be blank")
      end

      it 'must be unique' do
        create(:canonical_book, item_code: book.item_code)
        validate
        expect(book.errors[:item_code]).to include('must be unique')
      end
    end

    describe 'unit weight' do
      it "can't be blank" do
        book.unit_weight = nil
        validate
        expect(book.errors[:unit_weight]).to include("can't be blank")
      end

      it 'must be a number' do
        book.unit_weight = 'foo'
        validate
        expect(book.errors[:unit_weight]).to include('is not a number')
      end

      it 'must be at least zero' do
        book.unit_weight = -3.14159
        validate
        expect(book.errors[:unit_weight]).to include('must be greater than or equal to 0')
      end
    end

    describe 'book type' do
      it 'must be one of the allowed types' do
        book.book_type = 'self-help'
        validate
        expect(book.errors[:book_type]).to include('must be a book type that exists in Skyrim')
      end
    end

    describe 'add_on' do
      it "can't be blank" do
        book.add_on = nil
        validate
        expect(book.errors[:add_on]).to include("can't be blank")
      end

      it 'must be a supported add-on' do
        book.add_on = 'fishing'
        validate
        expect(book.errors[:add_on]).to include('must be a SIM-supported add-on or DLC')
      end
    end

    describe 'max_quantity' do
      it 'must be greater than zero' do
        book.max_quantity = 0
        validate
        expect(book.errors[:max_quantity]).to include('must be an integer of at least 1')
      end

      it 'must be an integer' do
        book.max_quantity = 7.64
        validate
        expect(book.errors[:max_quantity]).to include('must be an integer of at least 1')
      end

      it 'can be NULL' do
        book.max_quantity = nil
        expect(book).to be_valid
      end
    end

    describe 'skill name' do
      context 'when the book is a skill book' do
        it "can't be blank" do
          book.book_type = 'skill book'
          validate
          expect(book.errors[:skill_name]).to include("can't be blank for skill books")
        end

        it 'must be a valid skill' do
          book.skill_name = 'kung-fu fighting'
          validate
          expect(book.errors[:skill_name]).to include('must be a skill that exists in Skyrim')
        end
      end

      context 'when the book is not a skill book' do
        it 'cannot be defined' do
          book.book_type = 'lore book'
          book.skill_name = 'One-Handed'
          validate
          expect(book.errors[:skill_name]).to include('can only be defined for skill books')
        end

        it 'can be blank' do
          book.book_type = 'recipe'
          book.skill_name = nil
          expect(book).to be_valid
        end
      end
    end

    describe 'purchasable' do
      it 'is required' do
        book.purchasable = nil
        validate
        expect(book.errors[:purchasable]).to include('must be true or false')
      end
    end

    describe 'collectible' do
      it 'is required' do
        book.collectible = nil
        validate
        expect(book.errors[:collectible]).to include('must be true or false')
      end
    end

    describe 'unique_item' do
      it 'is required' do
        book.unique_item = nil
        validate
        expect(book.errors[:unique_item]).to include('must be true or false')
      end

      it 'must be true if max quantity is 1' do
        book.max_quantity = 1
        book.unique_item = false

        validate

        expect(book.errors[:unique_item]).to include('must be true if max quantity is 1')
      end

      it 'must be false if max quantity is not 1' do
        book.max_quantity = nil
        book.unique_item = true

        validate

        expect(book.errors[:unique_item]).to include('must correspond to a max quantity of 1')
      end
    end

    describe 'rare_item' do
      it 'is required' do
        book.rare_item = nil
        validate
        expect(book.errors[:rare_item]).to include('must be true or false')
      end

      it 'must be true if the item is unique' do
        book.unique_item = true
        book.rare_item = false
        validate
        expect(book.errors[:rare_item]).to include('must be true if item is unique')
      end
    end

    describe 'solstheim_only' do
      it 'is required' do
        book.solstheim_only = nil
        validate
        expect(book.errors[:solstheim_only]).to include('must be true or false')
      end
    end

    describe 'quest_item' do
      it 'is required' do
        book.quest_item = nil
        validate
        expect(book.errors[:quest_item]).to include('must be true or false')
      end
    end
  end

  describe 'default behavior' do
    it 'upcases item codes' do
      book = create(:canonical_book, item_code: 'abc123')
      expect(book.reload.item_code).to eq('ABC123')
    end
  end

  describe '::unique_identifier' do
    it 'returns ":item_code"' do
      expect(described_class.unique_identifier).to eq(:item_code)
    end
  end
end

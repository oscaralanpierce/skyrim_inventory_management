# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Book, type: :model do
  describe 'validations' do
    subject(:validate) { book.validate }

    let(:book) { build(:book) }

    it 'is invalid without a title' do
      book.title = nil
      validate

      expect(book.errors[:title]).to include("can't be blank")
    end

    it 'is invalid with a negative unit_weight' do
      book.unit_weight = -4.2
      validate

      expect(book.errors[:unit_weight]).to include('must be greater than or equal to 0')
    end

    describe 'canonical model validations' do
      let(:book) { build(:book, canonical_book:, game:) }
      let(:game) { create(:game) }

      context 'when the canonical model is not unique' do
        let(:canonical_book) { create(:canonical_book) }

        before do
          create_list(
            :book,
            3,
            canonical_book:,
            game:,
          )
        end

        it 'is valid' do
          expect(book).to be_valid
        end
      end

      context 'when the canonical model is unique' do
        let(:canonical_book) do
          create(
            :canonical_book,
            max_quantity: 1,
            unique_item: true,
            rare_item: true,
          )
        end

        context 'when the canonical model has no books' do
          it 'is valid' do
            expect(book).to be_valid
          end
        end

        context 'when the canonical model has a book for another game' do
          before do
            create(:book, canonical_book:)
          end

          it 'is valid' do
            expect(book).to be_valid
          end
        end

        context 'when the canonical model has a book for the same game' do
          before do
            create(:book, canonical_book:, game:)
          end

          it 'is invalid' do
            validate
            expect(book.errors[:base]).to include('is a duplicate of a unique in-game item')
          end
        end
      end
    end
  end

  describe '#canonical_model' do
    subject(:canonical_model) { book.canonical_model }

    context 'when there is a canonical book present' do
      let(:book) { build(:book, :with_matching_canonical) }

      it 'returns the canonical book' do
        expect(canonical_model).to eq(book.canonical_book)
      end
    end

    context 'when there is no canonical book present' do
      let(:book) { build(:book) }

      it 'is nil' do
        expect(canonical_model).to be_nil
      end
    end
  end

  describe '#canonical_models' do
    subject(:canonical_models) { book.canonical_models }

    context 'when there is a single matching canonical model' do
      let(:book) { build(:book, title: 'foo', unit_weight: 2) }

      before do
        create(:canonical_book, title: 'Foo', unit_weight: 2)
        create(:canonical_book, title: 'foo', unit_weight: 1)
      end

      it 'returns the single matching canonical' do
        expect(canonical_models).to contain_exactly(Canonical::Book.first)
      end
    end

    context 'when there are multiple matching canonical models' do
      let(:book) { build(:book, title: 'foo', unit_weight: 2) }

      before do
        create(:canonical_book, title: 'Foo', unit_weight: 2)
        create(:canonical_book, title: 'foo', unit_weight: 1)
        create(:canonical_book, title: 'Bar', title_variants: %w[Foo], unit_weight: 2)
      end

      it 'includes all matching canonicals' do
        expect(canonical_models).to contain_exactly(Canonical::Book.first, Canonical::Book.last)
      end
    end

    context 'when the matching canonical changes' do
      let(:book) { create(:book, :with_matching_canonical) }

      let!(:new_canonical) do
        create(
          :canonical_book,
          title: 'Black Book: Epistolary Acumen',
          unit_weight: 1,
          book_type: 'Black Book',
          authors: ['The Transparent One'],
        )
      end

      it 'identifies the new canonical model' do
        book.title = 'Black book: epistolary acumen'
        book.unit_weight = nil
        book.authors = ['The Transparent One']

        expect(canonical_models).to contain_exactly(new_canonical)
      end
    end

    context 'when the book is a recipe (matching involves ingredients)' do
      let(:book) { create(:book, title: 'foo') }

      before do
        create(:canonical_recipe, title: 'Foo')
        create(:canonical_recipe, title: 'Bar', title_variants: %w[Foo Baz])

        create(
          :recipes_canonical_ingredient,
          recipe: book,
          ingredient: Canonical::Book.last.canonical_ingredients.first,
        )

        book.canonical_ingredients.reload
      end

      it 'matches based on the association' do
        expect(canonical_models).to contain_exactly(Canonical::Book.last)
      end
    end
  end

  describe '#recipe?' do
    subject(:recipe) { book.recipe? }

    let(:book) { create(:book, title: 'foo') }

    context 'when all matching canonicals are recipes' do
      before do
        create_list(
          :canonical_recipe,
          2,
          title: 'Foo',
        )
      end

      it 'returns true' do
        expect(recipe).to be(true)
      end
    end

    context 'when at least one matching canonical is a recipe' do
      before do
        create(:canonical_recipe, title: 'Foo')
        create(:canonical_book, title: 'Foo', book_type: 'Black Book')
      end

      it 'returns true' do
        expect(recipe).to be(true)
      end
    end

    context 'when no matching canonicals are recipes' do
      before do
        create_list(:canonical_book, 2, title: 'Foo', book_type: 'lore book')
      end

      it 'returns false' do
        expect(recipe).to be(false)
      end
    end
  end

  describe '::before_validation' do
    subject(:validate) { book.validate }

    context 'when there is one matching canonical book' do
      let(:book) { build(:book, title: 'foo') }

      before do
        create(:canonical_book, title: 'Bar')
        create(
          :canonical_book,
          title: 'Baz',
          title_variants: %w[Foo],
          unit_weight: 13,
          authors: ['Toni Morrison', 'Maya Angelou'],
          book_type: 'skill book',
          skill_name: 'Alteration',
        )
      end

      it 'assigns the matching canonical as the canonical book' do
        validate
        expect(book.canonical_book).to eq(Canonical::Book.last)
      end

      it 'sets values on the model based on the canonical', :aggregate_failures do
        validate
        expect(book.title).to eq('Baz')
        expect(book.authors).to eq(['Toni Morrison', 'Maya Angelou'])
        expect(book.unit_weight).to eq(13)
        expect(book.skill_name).to eq('Alteration')
      end
    end

    context 'when there are multiple matching canonical books' do
      let(:book) { build(:book, title: 'foo') }

      before do
        create_list(
          :canonical_book,
          2,
          title: 'Baz',
          title_variants: %w[Foo],
          unit_weight: 13,
          authors: ['Toni Morrison', 'Maya Angelou'],
          book_type: 'skill book',
          skill_name: 'Alteration',
        )
      end

      it "doesn't assign a canonical book" do
        validate
        expect(book.canonical_book).to be_nil
      end

      it "doesn't update values", :aggregate_failures do
        validate
        expect(book.title).to eq('foo')
        expect(book.authors).to be_blank
        expect(book.unit_weight).to be_nil
        expect(book.skill_name).to be_nil
      end
    end

    context 'when updating the attributes of an in-game item' do
      let(:book) { create(:book, :with_matching_canonical) }

      context 'when the update results in a new canonical match' do
        let!(:new_canonical) do
          create(
            :canonical_book,
            title: "Sinderion's Field Journal",
          )
        end

        it 'changes the canonical association' do
          book.title = "sinderion's field journal"

          expect { validate }
            .to change(book, :canonical_book)
                  .to(new_canonical)
        end

        it 'updates attributes' do
          book.title = "sinderion's field journal"

          validate

          expect(book.title).to eq("Sinderion's Field Journal")
        end
      end

      context 'when the update results in an ambiguous match' do
        before do
          create_list(
            :canonical_book,
            2,
            title: "Sinderion's Field Journal",
          )
        end

        it 'sets the canonical_book to nil' do
          book.title = "sinderion's field journal"

          expect { validate }
            .to change(book, :canonical_book)
                  .to(nil)
        end

        it "doesn't update attributes" do
          book.title = "sinderion's field journal"

          validate

          expect(book.title).not_to eq("Sinderion's Field Journal")
        end
      end

      context 'when the update results in no canonical matches' do
        it 'sets the canonical_book to nil' do
          book.title = "sinderion's field journal"

          expect { validate }
            .to change(book, :canonical_book)
                  .to(nil)
        end
      end
    end
  end
end

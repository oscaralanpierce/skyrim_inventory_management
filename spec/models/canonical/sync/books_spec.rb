# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Sync::Books do
  # Use let! because if we wait to evaluate these until we've run the
  # examples, the stub in the before block will prevent `File.read` from
  # running.
  let(:json_path) { Rails.root.join('spec', 'support', 'fixtures', 'canonical', 'sync', 'books.json') }
  let!(:json_data) { File.read(json_path) }

  before do
    allow(File).to receive(:read).and_return(json_data)
  end

  describe '::perform' do
    subject(:perform) { described_class.perform(preserve_existing_records:) }

    context 'when preserve_existing_records is false' do
      let(:preserve_existing_records) { false }

      context 'when there are no existing books in the database' do
        let(:syncer) { described_class.new(preserve_existing_records:) }

        before do
          create(:canonical_ingredient, item_code: '00052695')
          create(:canonical_ingredient, item_code: '0006BC00')
        end

        it 'instantiates itself' do
          allow(described_class).to receive(:new).and_return(syncer)
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records:)
        end

        it 'populates the models from the JSON file' do
          perform
          expect(Canonical::Book.count).to eq(4)
        end

        it 'creates the associations to canonical ingredients where they exist', :aggregate_failures do
          perform
          expect(Canonical::Book.find_by(item_code: '0001AFD9').canonical_ingredients.length).to eq(0)
          expect(Canonical::Book.find_by(item_code: '0001ACE5').canonical_ingredients.length).to eq(0)
          expect(Canonical::Book.find_by(item_code: '000F5CB8').canonical_ingredients.length).to eq(2)
          expect(Canonical::Book.find_by(item_code: 'XX030C9A').canonical_ingredients.length).to eq(0)
        end
      end

      context 'when there are existing book records in the database' do
        let!(:book_in_json) do
          create(
            :canonical_recipe,
            item_code: '000F5CB8',
            title: 'The Seven Habits of Highly Successful People',
          )
        end

        let!(:book_not_in_json) { create(:canonical_book, item_code: '12345678') }
        let(:syncer) { described_class.new(preserve_existing_records:) }

        before do
          create(:canonical_ingredient, item_code: '00052695')
          create(:canonical_ingredient, item_code: '0006BC00')
        end

        it 'instantiates itself' do
          allow(described_class).to receive(:new).and_return(syncer)
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records:)
        end

        it 'updates models that were already in the database' do
          perform
          expect(book_in_json.reload.title).to eq('Cure Disease Potion Recipe')
        end

        it "removes models in the database that aren't in the JSON data" do
          perform
          expect(Canonical::Book.find_by(item_code: '12345678')).to be_nil
        end

        it 'adds new models to the database', :aggregate_failures do
          perform
          expect(Canonical::Book.find_by(item_code: '0001AFD9')).to be_present
          expect(Canonical::Book.find_by(item_code: '0001ACE5')).to be_present
          expect(Canonical::Book.find_by(item_code: 'XX030C9A')).to be_present
        end

        it "removes canonical ingredient associations that don't exist in the JSON data" do
          book_in_json
            .canonical_ingredients
            .create!(
              item_code: '12345678',
              name: 'Venus Fly Trap',
              unit_weight: 1,
              add_on: 'base',
              collectible: true,
              purchasable: false,
              rare_item: true,
            )

          perform

          expect(book_in_json.canonical_ingredients.find_by(name: 'Venus Fly Trap')).to be_nil
        end

        it 'adds canonical ingredients if they exist' do
          perform
          expect(book_in_json.canonical_ingredients.count).to eq(2)
        end
      end

      context 'when there are no canonical ingredients in the database' do
        before do
          allow(Rails.logger).to receive(:error)
        end

        it "logs an error and doesn't create models", :aggregate_failures do
          expect { perform }
            .to raise_error(Canonical::Sync::PrerequisiteNotMetError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Prerequisite(s) not met: sync Canonical::Ingredient before canonical books')

          expect(Canonical::Book.count).to eq(0)
        end
      end

      context 'when a canonical ingredient is missing' do
        before do
          # prevent it from erroring out, which it will do if there are no
          # ingredients at all
          create(:canonical_ingredient)
          allow(Rails.logger).to receive(:error).twice
        end

        it 'logs a validation error', :aggregate_failures do
          expect { perform }
            .to raise_error(ActiveRecord::RecordInvalid)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Validation error saving associations for canonical book "000F5CB8": Validation failed: Ingredient must exist')
        end
      end
    end

    context 'when preserve_existing_records is true' do
      let(:syncer) { described_class.new(preserve_existing_records:) }
      let(:preserve_existing_records) { true }
      let!(:book_in_json) { create(:canonical_recipe, item_code: '000F5CB8', title: 'Rich Dad, Poor Dad') }
      let!(:book_not_in_json) { create(:canonical_book, item_code: '12345678') }

      before do
        create(:canonical_ingredient, item_code: '00052695')
        create(:canonical_ingredient, item_code: '0006BC00')
        create(:recipes_canonical_ingredient, recipe: book_in_json)
      end

      it 'instantiates itself' do
        allow(described_class).to receive(:new).and_return(syncer)
        perform
        expect(described_class).to have_received(:new).with(preserve_existing_records:)
      end

      it 'updates models found in the JSON data' do
        perform
        expect(book_in_json.reload.title).to eq('Cure Disease Potion Recipe')
      end

      it 'adds models not already in the database', :aggregate_failures do
        perform
        expect(Canonical::Book.find_by(item_code: '0001AFD9')).to be_present
        expect(Canonical::Book.find_by(item_code: '0001ACE5')).to be_present
        expect(Canonical::Book.find_by(item_code: 'XX030C9A')).to be_present
      end

      it "doesn't destroy models that aren't in the JSON data" do
        perform
        expect(book_not_in_json.reload).to be_present
      end

      it "doesn't destroy associations" do
        perform
        expect(book_in_json.reload.canonical_ingredients.length).to eq(5)
      end
    end

    describe 'error logging' do
      let(:preserve_existing_records) { false }

      context 'when an ActiveRecord::RecordInvalid error is raised' do
        let(:errored_model) do
          instance_double Canonical::Book,
                          errors:,
                          class: class_double(Canonical::Book, i18n_scope: :activerecord)
        end

        let(:errors) { double('errors', full_messages: ["Title can't be blank"]) }

        before do
          create(:canonical_ingredient)

          allow_any_instance_of(Canonical::Book)
            .to receive(:save!)
                  .and_raise(ActiveRecord::RecordInvalid, errored_model)

          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(ActiveRecord::RecordInvalid)

          expect(Rails.logger)
            .to have_received(:error)
                  .with("Error saving canonical book \"000F5CB8\": Validation failed: Title can't be blank")
        end
      end

      context 'when another error is raised pertaining to a specific model' do
        before do
          create(:canonical_ingredient)

          allow(Canonical::Book)
            .to receive(:find_or_initialize_by)
                  .and_raise(StandardError, 'foobar')

          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Unexpected error StandardError saving canonical book "000F5CB8": foobar')
        end
      end

      context 'when an error is raised not pertaining to a specific model' do
        before do
          create(:canonical_ingredient)

          allow(Canonical::Book)
            .to receive(:where)
                  .and_raise(StandardError, 'foobar')

          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Unexpected error StandardError while syncing canonical books: foobar')
        end
      end
    end
  end
end

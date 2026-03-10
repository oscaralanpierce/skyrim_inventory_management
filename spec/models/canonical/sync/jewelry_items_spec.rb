# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Sync::JewelryItems do
  # Use let! because if we wait to evaluate these until we've run the
  # examples, the stub in the before block will prevent `File.read` from
  # running.
  let(:json_path) { Rails.root.join('spec', 'support', 'fixtures', 'canonical', 'sync', 'jewelry_items.json') }
  let!(:json_data) { File.read(json_path) }

  before do
    allow(File).to receive(:read).and_return(json_data)
  end

  describe '::perform' do
    subject(:perform) { described_class.perform(preserve_existing_records) }

    context 'when preserve_existing_records is false' do
      let(:preserve_existing_records) { false }

      context 'when there are no existing jewelry items in the database' do
        let(:syncer) { described_class.new(preserve_existing_records) }

        before do
          create(:enchantment, name: 'Fortify Health')
        end

        it 'instantiates itseslf' do
          allow(described_class).to receive(:new).and_return(syncer)
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records)
        end

        it 'populates the models from the JSON file' do
          expect { perform }
            .to change(Canonical::JewelryItem, :count).from(0).to(4)
        end

        it 'creates the associations to enchantments where they exist', :aggregate_failures do
          perform
          expect(Canonical::JewelryItem.find_by(item_code: '00094E3E').enchantments.length).to eq(1)
          expect(Canonical::JewelryItem.find_by(item_code: '000F5A1D').enchantments.length).to eq(0)
          expect(Canonical::JewelryItem.find_by(item_code: '000DA735').enchantments.length).to eq(0)
          expect(Canonical::JewelryItem.find_by(item_code: 'XX01AA0B').enchantments.length).to eq(0)
        end
      end

      context 'when there are existing jewelry item records in the database' do
        let!(:item_in_json) { create(:canonical_jewelry_item, item_code: '00094E3E', jewelry_type: 'ring') }
        let!(:item_not_in_json) { create(:canonical_jewelry_item, item_code: '12345678') }
        let(:syncer) { described_class.new(preserve_existing_records) }

        before do
          create(:enchantment, name: 'Fortify Health')
        end

        it 'instantiates itself' do
          allow(described_class).to receive(:new).and_return(syncer)
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records)
        end

        it 'updates models that were already in the database' do
          perform
          expect(item_in_json.reload.jewelry_type).to eq('amulet')
        end

        it "removes models in the database that aren't in the JSON data" do
          perform
          expect(Canonical::JewelryItem.find_by(item_code: '12345678')).to be_nil
        end

        it 'adds new models to the database', :aggregate_failures do
          perform
          expect(Canonical::JewelryItem.find_by(item_code: '000F5A1D')).to be_present
          expect(Canonical::JewelryItem.find_by(item_code: '000DA735')).to be_present
          expect(Canonical::JewelryItem.find_by(item_code: 'XX01AA0B')).to be_present
        end

        it 'adds associations if they exist' do
          perform
          expect(item_in_json.enchantments.length).to eq(1)
        end
      end

      context 'when there are no enchantments in the database' do
        before do
          allow(Rails.logger).to receive(:error)
        end

        it "logs an error and doesn't create models", :aggregate_failures do
          expect { perform }
            .to raise_error(Canonical::Sync::PrerequisiteNotMetError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Prerequisite(s) not met: sync Enchantment before canonical jewelry items')
          expect(Canonical::JewelryItem.count).to eq(0)
        end
      end

      context 'when an enchantment is missing' do
        before do
          # prevent it from erroring out, which it will do if there are no
          # enchantments at all
          create(:enchantment)

          allow(Rails.logger).to receive(:error).twice
        end

        it 'logs a validation error', :aggregate_failures do
          expect { perform }
            .to raise_error(ActiveRecord::RecordInvalid)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Validation error saving associations for canonical jewelry item "00094E3E": Validation failed: Enchantment must exist')
        end
      end
    end

    context 'when preserve_existing_records is true' do
      let(:preserve_existing_records) { true }
      let(:syncer) { described_class.new(preserve_existing_records) }
      let!(:item_in_json) { create(:canonical_jewelry_item, item_code: '00094E3E', jewelry_type: 'circlet') }
      let!(:item_not_in_json) { create(:canonical_jewelry_item, item_code: '12345678') }

      before do
        create(:enchantment, name: 'Fortify Health')
      end

      it 'instantiates itself' do
        allow(described_class).to receive(:new).and_return(syncer)
        perform
        expect(described_class).to have_received(:new).with(preserve_existing_records)
      end

      it 'updates models found in the JSON data' do
        perform
        expect(item_in_json.reload.jewelry_type).to eq('amulet')
      end

      it 'adds models not already in the database', :aggregate_failures do
        perform
        expect(Canonical::JewelryItem.find_by(item_code: '000F5A1D')).to be_present
        expect(Canonical::JewelryItem.find_by(item_code: '000DA735')).to be_present
        expect(Canonical::JewelryItem.find_by(item_code: 'XX01AA0B')).to be_present
      end

      it "doesn't destroy models that aren't in the JSON data" do
        perform
        expect(item_not_in_json.reload).to be_present
      end
    end

    describe 'error logging' do
      let(:preserve_existing_records) { false }

      context 'when an ActiveRecord::RecordInvalid error is raised' do
        let(:errored_model) do
          instance_double Canonical::JewelryItem,
                          errors:,
                          class: class_double(Canonical::JewelryItem, i18n_scope: :activerecord)
        end

        let(:errors) { double('errors', full_messages: ["Name can't be blank"]) }

        before do
          create(:enchantment)

          allow_any_instance_of(Canonical::JewelryItem)
            .to receive(:save!)
                  .and_raise(ActiveRecord::RecordInvalid, errored_model)
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(ActiveRecord::RecordInvalid)

          expect(Rails.logger)
            .to have_received(:error)
                  .with("Error saving canonical jewelry item \"00094E3E\": Validation failed: Name can't be blank")
        end
      end

      context 'when another error is raised pertaining to a specific model' do
        before do
          create(:enchantment)

          allow(Canonical::JewelryItem).to receive(:find_or_initialize_by).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Unexpected error StandardError saving canonical jewelry item "00094E3E": foobar')
        end
      end

      context 'when an error is raised not pertaining to a specific model' do
        before do
          create(:enchantment)

          allow(Canonical::JewelryItem).to receive(:where).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Unexpected error StandardError while syncing canonical jewelry items: foobar')
        end
      end
    end
  end
end

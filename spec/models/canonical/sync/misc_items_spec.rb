# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Sync::MiscItems do
  # Use let! because if we wait to evaluate these until we've run the
  # examples, the stub in the before block will prevent `File.read` from
  # running.
  let(:json_path) { Rails.root.join('spec', 'support', 'fixtures', 'canonical', 'sync', 'misc_items.json') }
  let!(:json_data) { File.read(json_path) }

  before do
    allow(File).to receive(:read).and_return(json_data)
  end

  describe '::perform' do
    subject(:perform) { described_class.perform(preserve_existing_records) }

    context 'when preserve_existing_records is false' do
      let(:preserve_existing_records) { false }
      let(:syncer) { described_class.new(preserve_existing_records) }

      before do
        allow(described_class).to receive(:new).and_return(syncer)
      end

      it 'instantiates itself' do
        perform
        expect(described_class).to have_received(:new).with(preserve_existing_records)
      end

      context 'when there are no existing records in the database' do
        it 'populates the models from the JSON file' do
          expect { perform }
            .to change(Canonical::MiscItem, :count).from(0).to(4)
        end
      end

      context 'when there are existing records in the database' do
        let!(:item_in_json) { create(:canonical_misc_item, item_code: 'XX012F97', name: 'Quartz Paragon') }
        let!(:item_not_in_json) { create(:canonical_misc_item, item_code: '12345678') }
        let(:syncer) { described_class.new(preserve_existing_records) }

        it 'instantiates itself' do
          allow(described_class).to receive(:new).and_return(syncer)
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records)
        end

        it 'updates models that were already in the database' do
          perform
          expect(item_in_json.reload.name).to eq('Amethyst Paragon')
        end

        it "removes models in the database that aren't in the JSON data" do
          perform
          expect(Canonical::MiscItem.find_by(item_code: '12345678')).to be_nil
        end

        it 'adds new models to the database', :aggregate_failures do
          perform
          expect(Canonical::MiscItem.find_by(item_code: '000F6767')).to be_present
          expect(Canonical::MiscItem.find_by(item_code: '0001F6D4')).to be_present
          expect(Canonical::MiscItem.find_by(item_code: '0003532C')).to be_present
        end
      end
    end

    context 'when preserve_existing_records is true' do
      let(:preserve_existing_records) { true }
      let(:syncer) { described_class.new(preserve_existing_records) }
      let!(:item_in_json) { create(:canonical_misc_item, item_code: 'XX012F97', name: 'Quartz Paragon') }
      let!(:item_not_in_json) { create(:canonical_misc_item, item_code: '12345678') }

      it 'instantiates itself' do
        allow(described_class).to receive(:new).and_return(syncer)
        perform
        expect(described_class).to have_received(:new).with(preserve_existing_records)
      end

      it 'updates models found in the JSON data' do
        perform
        expect(item_in_json.reload.name).to eq('Amethyst Paragon')
      end

      it 'adds models not already in the database', :aggregate_failures do
        perform
        expect(Canonical::MiscItem.find_by(item_code: '000F6767')).to be_present
        expect(Canonical::MiscItem.find_by(item_code: '0001F6D4')).to be_present
        expect(Canonical::MiscItem.find_by(item_code: '0003532C')).to be_present
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
          instance_double Canonical::MiscItem,
                          errors:,
                          class: class_double(Canonical::MiscItem, i18n_scope: :activerecord)
        end

        let(:errors) { double('errors', full_messages: ["Name can't be blank"]) }

        before do
          allow_any_instance_of(Canonical::MiscItem)
            .to receive(:save!)
                  .and_raise(ActiveRecord::RecordInvalid, errored_model)

          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(ActiveRecord::RecordInvalid)

          expect(Rails.logger)
            .to have_received(:error)
                  .with("Error saving canonical misc item \"XX012F97\": Validation failed: Name can't be blank")
        end
      end

      context 'when another error is raised pertaining to a specific model' do
        before do
          allow(Canonical::MiscItem).to receive(:find_or_initialize_by).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Unexpected error StandardError saving canonical misc item "XX012F97": foobar')
        end
      end

      context 'when an error is raised not pertaining to a specific model' do
        before do
          allow(Canonical::MiscItem).to receive(:where).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Unexpected error StandardError while syncing canonical misc items: foobar')
        end
      end
    end
  end
end

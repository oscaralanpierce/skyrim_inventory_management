# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Sync::Armor do
  # Use let! because if we wait to evaluate these until we've run the
  # examples, the stub in the before block will prevent `File.read` from
  # running.
  let(:json_path) { Rails.root.join('spec', 'support', 'fixtures', 'canonical', 'sync', 'armor.json') }
  let!(:json_data) { File.read(json_path) }

  before { allow(File).to receive(:read).and_return(json_data) }

  describe '::perform' do
    subject(:perform) { described_class.perform(preserve_existing_records) }

    context 'when preserve_existing_records is false' do
      let(:preserve_existing_records) { false }

      context 'when there are no existing armor items in the database' do
        let(:syncer) { described_class.new(preserve_existing_records) }

        before do
          create(:enchantment, name: 'Fortify Block')
          allow(described_class).to receive(:new).and_return(syncer)
        end

        it 'instantiates itseslf' do
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records)
        end

        it 'populates the models from the JSON file', :aggregate_failures do
          expect { perform }
            .to change(Canonical::Armor, :count).from(0).to(4)
        end

        it 'creates the associations to enchantments where they exist', :aggregate_failures do
          perform
          expect(Canonical::Armor.find_by(item_code: 'XX01DB97').enchantments.length).to eq 0
          expect(Canonical::Armor.find_by(item_code: '000B50EF').enchantments.length).to eq 1
          expect(Canonical::Armor.find_by(item_code: '0001391A').enchantments.length).to eq 0
          expect(Canonical::Armor.find_by(item_code: '00013966').enchantments.length).to eq 0
        end
      end

      context 'when there are existing armor item records in the database' do
        let!(:item_in_json) { create(:canonical_armor, item_code: 'XX01DB97', body_slot: 'feet') }
        let!(:item_not_in_json) { create(:canonical_armor, item_code: '12345678') }
        let(:syncer) { described_class.new(preserve_existing_records) }

        before { create(:enchantment, name: 'Fortify Block') }

        it 'instantiates itself' do
          allow(described_class).to receive(:new).and_return(syncer)
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records)
        end

        it 'updates models that were already in the database' do
          perform
          expect(item_in_json.reload.body_slot).to eq 'body'
        end

        it "removes models in the database that aren't in the JSON data" do
          perform
          expect(Canonical::Armor.find_by(item_code: '12345678')).to be_nil
        end

        it 'adds new models to the database', :aggregate_failures do
          perform
          expect(Canonical::Armor.find_by(item_code: '000B50EF')).to be_present
          expect(Canonical::Armor.find_by(item_code: '0001391A')).to be_present
          expect(Canonical::Armor.find_by(item_code: '00013966')).to be_present
        end
      end

      context 'when there are no enchantments in the database' do
        before { allow(Rails.logger).to receive(:error) }

        it "logs an error and doesn't create models", :aggregate_failures do
          expect { perform }
            .to raise_error(Canonical::Sync::PrerequisiteNotMetError)

          expect(Rails.logger).to have_received(:error).with('Prerequisite(s) not met: sync Enchantment before canonical armors')

          expect(Canonical::JewelryItem.count).to eq 0
        end
      end

      context 'when an enchantment is missing' do
        before do
          # prevent it from erroring out, which it will do if there are no
          # enchantments at all
          create(:enchantment)
          allow(Rails.logger).to receive(:error)
        end

        it 'logs a validation error', :aggregate_failures do
          expect { perform }
            .to raise_error ActiveRecord::RecordInvalid

          expect(Rails.logger).to have_received(:error).with('Validation error saving associations for canonical armor "000B50EF": Validation failed: Enchantment must exist')
        end
      end
    end

    context 'when preserve_existing_records is true' do
      let(:preserve_existing_records) { true }
      let(:syncer) { described_class.new(preserve_existing_records) }
      let!(:item_in_json) { create(:canonical_armor, item_code: 'XX01DB97', body_slot: 'hands') }
      let!(:item_not_in_json) { create(:canonical_armor, item_code: '12345678') }

      before { create(:enchantment, name: 'Fortify Block') }

      it 'instantiates itself' do
        allow(described_class).to receive(:new).and_return(syncer)
        perform
        expect(described_class).to have_received(:new).with(preserve_existing_records)
      end

      it 'updates models found in the JSON data' do
        perform
        expect(item_in_json.reload.body_slot).to eq 'body'
      end

      it 'adds models not already in the database', :aggregate_failures do
        perform
        expect(Canonical::Armor.find_by(item_code: '000B50EF')).to be_present
        expect(Canonical::Armor.find_by(item_code: '0001391A')).to be_present
        expect(Canonical::Armor.find_by(item_code: '00013966')).to be_present
      end

      it "doesn't destroy models that aren't in the JSON data" do
        perform
        expect(item_not_in_json.reload).to be_present
      end
    end

    describe 'error logging' do
      let(:preserve_existing_records) { false }

      context 'when an ActiveRecord::RecordInvalid error is raised' do
        let(:errored_model) { instance_double Canonical::Armor, errors:, class: class_double(Canonical::Armor, i18n_scope: :activerecord) }

        let(:errors) { double('errors', full_messages: ["Name can't be blank"]) }

        before do
          create(:enchantment)

          allow_any_instance_of(Canonical::Armor).to receive(:save!).and_raise(ActiveRecord::RecordInvalid, errored_model)
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(ActiveRecord::RecordInvalid)

          expect(Rails.logger).to have_received(:error).with("Error saving canonical armor \"XX01DB97\": Validation failed: Name can't be blank")
        end
      end

      context 'when another error is raised pertaining to a specific model' do
        before do
          create(:enchantment)

          allow(Canonical::Armor).to receive(:find_or_initialize_by).and_raise(StandardError, 'foobar')

          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger).to have_received(:error).with('Unexpected error StandardError saving canonical armor "XX01DB97": foobar')
        end
      end

      context 'when an error is raised not pertaining to a specific model' do
        before do
          create(:enchantment)

          allow(Canonical::Armor).to receive(:where).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger).to have_received(:error).with('Unexpected error StandardError while syncing canonical armors: foobar')
        end
      end
    end
  end
end

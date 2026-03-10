# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Sync::Spells do
  # Use let! because if we wait to evaluate these until we've run the
  # examples, the stub in the before block will prevent `File.read` from
  # running.
  let(:json_path) { Rails.root.join('spec', 'support', 'fixtures', 'canonical', 'sync', 'spells.json') }
  let!(:json_data) { File.read(json_path) }

  before do
    allow(File).to receive(:read).and_return(json_data)
  end

  describe '::perform' do
    subject(:perform) { described_class.perform(preserve_existing_records:) }

    context 'when preserve_existing_records is false' do
      let(:preserve_existing_records) { false }
      let(:syncer) { described_class.new(preserve_existing_records:) }

      before do
        allow(described_class).to receive(:new).and_return(syncer)
      end

      it 'instantiates itself' do
        perform
        expect(described_class).to have_received(:new).with(preserve_existing_records:)
      end

      context 'when there are no existing records in the database' do
        it 'populates the models from the JSON file', :aggregate_failures do
          perform
          expect(Spell.find_by(name: 'Bound Battleaxe')).to be_present
          expect(Spell.find_by(name: 'Bound Bow')).to be_present
          expect(Spell.find_by(name: 'Bound Dagger')).to be_present
          expect(Spell.find_by(name: 'Bound Sword')).to be_present
        end
      end

      context 'when there are existing records in the database' do
        let!(:spell_in_json) { create(:spell, name: 'Bound Battleaxe', strength_unit: 'point', strength: 50) }
        let!(:spell_not_in_json) { create(:spell, name: 'My Awesome Spell') }
        let(:syncer) { described_class.new(preserve_existing_records:) }

        it 'instantiates itself' do
          allow(described_class).to receive(:new).and_return(syncer)
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records:)
        end

        it 'updates models that were already in the database', :aggregate_failures do
          perform
          expect(spell_in_json.reload.strength_unit).to be_nil
          expect(spell_in_json.strength).to be_nil
        end

        it "removes models in the database that aren't in the JSON data" do
          perform
          expect(Spell.find_by(name: 'My Awesome Spell')).to be_nil
        end

        it 'adds new models to the database', :aggregate_failures do
          perform
          expect(Spell.find_by(name: 'Bound Bow')).to be_present
          expect(Spell.find_by(name: 'Bound Dagger')).to be_present
          expect(Spell.find_by(name: 'Bound Sword')).to be_present
        end
      end
    end

    context 'when preserve_existing_records is true' do
      let(:preserve_existing_records) { true }
      let(:syncer) { described_class.new(preserve_existing_records:) }
      let!(:spell_in_json) { create(:spell, name: 'Bound Bow', strength_unit: 'percentage', strength: 20) }
      let!(:spell_not_in_json) { create(:spell, name: 'My Awesome Spell') }

      before do
        allow(described_class).to receive(:new).and_return(syncer)
      end

      it 'instantiates itself' do
        perform
        expect(described_class).to have_received(:new).with(preserve_existing_records:)
      end

      it 'updates models found in the JSON data', :aggregate_failures do
        perform
        expect(spell_in_json.reload.strength_unit).to be_nil
        expect(spell_in_json.strength).to be_nil
      end

      it 'adds models not already in the database', :aggregate_failures do
        perform
        expect(Spell.find_by(name: 'Bound Bow')).to be_present
        expect(Spell.find_by(name: 'Bound Dagger')).to be_present
        expect(Spell.find_by(name: 'Bound Sword')).to be_present
      end

      it "doesn't destroy models that aren't in the JSON data" do
        perform
        expect(spell_not_in_json.reload).to be_present
      end
    end

    describe 'error logging' do
      let(:preserve_existing_records) { false }

      context 'when an ActiveRecord::RecordInvalid error is raised' do
        let(:errored_model) do
          instance_double Spell,
                          errors:,
                          class: class_double(Spell, i18n_scope: :activerecord)
        end

        let(:errors) { double('errors', full_messages: ["Name can't be blank"]) }

        before do
          allow_any_instance_of(Spell)
            .to receive(:save!)
                  .and_raise(ActiveRecord::RecordInvalid, errored_model)
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(ActiveRecord::RecordInvalid)

          expect(Rails.logger)
            .to have_received(:error)
                  .with("Error saving spell \"Bound Battleaxe\": Validation failed: Name can't be blank")
        end
      end

      context 'when another error is raised pertaining to a specific model' do
        before do
          allow(Spell).to receive(:find_or_initialize_by).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Unexpected error StandardError saving spell "Bound Battleaxe": foobar')
        end
      end

      context 'when an error is raised not pertaining to a specific model' do
        before do
          allow(Spell).to receive(:where).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Unexpected error StandardError while syncing spells: foobar')
        end
      end
    end
  end
end

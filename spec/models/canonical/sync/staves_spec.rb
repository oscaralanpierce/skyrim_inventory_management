# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Sync::Staves do
  # Use let! because if we wait to evaluate these until we've run the
  # examples, the stub in the before block will prevent `File.read` from
  # running.
  let(:json_path) { Rails.root.join('spec', 'support', 'fixtures', 'canonical', 'sync', 'staves.json') }
  let!(:json_data) { File.read(json_path) }

  let(:spell_names) do
    [
      'Soul Trap',
      'Pacify',
      'Turn Lesser Undead',
    ]
  end

  before do
    allow(File).to receive(:read).and_return(json_data)
  end

  describe '::perform' do
    subject(:perform) { described_class.perform(preserve_existing_records) }

    context 'when preserve_existing_records is false' do
      let(:preserve_existing_records) { false }

      context 'when there are no existing staves in the database' do
        let(:syncer) { described_class.new(preserve_existing_records) }

        before do
          spell_names.each {|name| create(:spell, name:) }

          create(:power, name: "Mora's Agony")
        end

        it 'instantiates itseslf' do
          allow(described_class).to receive(:new).and_return(syncer)
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records)
        end

        it 'populates the models from the JSON file' do
          perform
          expect(Canonical::Staff.count).to eq(4)
        end

        it 'creates the associations to spells where they exist', :aggregate_failures do
          perform
          expect(Canonical::Staff.find_by(item_code: '000AB704').spells.length).to eq(2)
          expect(Canonical::Staff.find_by(item_code: '00029B94').spells.length).to eq(1)
          expect(Canonical::Staff.find_by(item_code: 'XX039FAC').spells.length).to eq(0)
          expect(Canonical::Staff.find_by(item_code: '0001CB36').spells.length).to eq(0)
        end

        it 'creates the associations to powers where they exist', :aggregate_failures do
          perform
          expect(Canonical::Staff.find_by(item_code: '000AB704').powers.length).to eq(0)
          expect(Canonical::Staff.find_by(item_code: '00029B94').powers.length).to eq(0)
          expect(Canonical::Staff.find_by(item_code: 'XX039FAC').powers.length).to eq(1)
          expect(Canonical::Staff.find_by(item_code: '0001CB36').powers.length).to eq(0)
        end
      end

      context 'when there are existing staff records in the database' do
        let!(:item_in_json) { create(:canonical_staff, item_code: '000AB704', magical_effects: 'Fucks up the target severely') }
        let!(:item_not_in_json) { create(:canonical_staff, item_code: '12345678') }
        let(:syncer) { described_class.new(preserve_existing_records) }

        before do
          spell_names.each {|name| create(:spell, name:) }

          create(:power, name: "Mora's Agony")
        end

        it 'instantiates itself' do
          allow(described_class).to receive(:new).and_return(syncer)
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records)
        end

        it 'updates models that were already in the database' do
          perform
          expect(item_in_json.reload.magical_effects).to be_nil
        end

        it "removes models in the database that aren't in the JSON data" do
          perform
          expect(Canonical::Staff.find_by(item_code: '12345678')).to be_nil
        end

        it 'adds new models to the database', :aggregate_failures do
          perform
          expect(Canonical::Staff.find_by(item_code: '00029B94')).to be_present
          expect(Canonical::Staff.find_by(item_code: 'XX039FAC')).to be_present
          expect(Canonical::Staff.find_by(item_code: '0001CB36')).to be_present
        end

        it "removes associations that don't exist in the JSON data" do
          item_in_json.canonical_powerables_powers.create!(power: create(:power))
          perform
          expect(item_in_json.powers.length).to eq(0)
        end

        it 'adds associations if they exist' do
          perform
          expect(item_in_json.spells.length).to eq(2)
        end
      end

      context 'when there are no spells or powers in the database' do
        before do
          allow(Rails.logger).to receive(:error)
        end

        it "logs an error and doesn't create models", :aggregate_failures do
          expect { perform }
            .to raise_error(Canonical::Sync::PrerequisiteNotMetError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Prerequisite(s) not met: sync Power, Spell before canonical staves')

          expect(Canonical::Staff.count).to eq(0)
        end
      end

      context 'when a power or spell is missing' do
        before do
          # prevent it from erroring out, which it will do if there are no
          # powers or spells at all
          create(:power)
          spell_names.each {|name| create(:spell, name:) }

          allow(Rails.logger).to receive(:error).twice
        end

        it 'logs a validation error', :aggregate_failures do
          expect { perform }
            .to raise_error(ActiveRecord::RecordInvalid)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Validation error saving associations for canonical staff "XX039FAC": Validation failed: Power must exist')
        end
      end
    end

    context 'when preserve_existing_records is true' do
      let(:preserve_existing_records) { true }
      let(:syncer) { described_class.new(preserve_existing_records) }
      let!(:item_in_json) { create(:canonical_staff, item_code: '000AB704', unit_weight: 27) }
      let!(:item_not_in_json) { create(:canonical_staff, item_code: '12345678') }

      before do
        spell_names.each {|name| create(:spell, name:) }
        create(:power, name: "Mora's Agony")
        create(:canonical_powerables_power, powerable: item_in_json, power: create(:power))
      end

      it 'instantiates itself' do
        allow(described_class).to receive(:new).and_return(syncer)
        perform
        expect(described_class).to have_received(:new).with(preserve_existing_records)
      end

      it 'updates models found in the JSON data' do
        perform
        expect(item_in_json.reload.unit_weight).to eq(8.0)
      end

      it 'adds models not already in the database', :aggregate_failures do
        perform
        expect(Canonical::Staff.find_by(item_code: '00029B94')).to be_present
        expect(Canonical::Staff.find_by(item_code: 'XX039FAC')).to be_present
        expect(Canonical::Staff.find_by(item_code: '0001CB36')).to be_present
      end

      it "doesn't destroy models that aren't in the JSON data" do
        perform
        expect(item_not_in_json.reload).to be_present
      end

      it "doesn't destroy associations" do
        perform
        expect(item_in_json.reload.powers.length).to eq(1)
      end
    end

    describe 'error logging' do
      let(:preserve_existing_records) { false }

      context 'when an ActiveRecord::RecordInvalid error is raised' do
        let(:errored_model) do
          instance_double Canonical::Staff,
                          errors:,
                          class: class_double(Canonical::Staff, i18n_scope: :activerecord)
        end

        let(:errors) { double('errors', full_messages: ["Name can't be blank"]) }

        before do
          create(:spell)
          create(:power)

          allow_any_instance_of(Canonical::Staff)
            .to receive(:save!)
                  .and_raise(ActiveRecord::RecordInvalid, errored_model)
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(ActiveRecord::RecordInvalid)

          expect(Rails.logger)
            .to have_received(:error)
                  .with("Error saving canonical staff \"000AB704\": Validation failed: Name can't be blank")
        end
      end

      context 'when another error is raised pertaining to a specific model' do
        before do
          create(:spell)
          create(:power)
          allow(Canonical::Staff).to receive(:find_or_initialize_by).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Unexpected error StandardError saving canonical staff "000AB704": foobar')
        end
      end

      context 'when an error is raised not pertaining to a specific model' do
        before do
          create(:spell)
          create(:power)

          allow(Canonical::Staff).to receive(:where).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Unexpected error StandardError while syncing canonical staves: foobar')
        end
      end
    end
  end
end

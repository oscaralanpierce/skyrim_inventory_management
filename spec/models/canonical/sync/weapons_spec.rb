# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Sync::Weapons do
  # Use let! because if we wait to evaluate these until we've run the
  # examples, the stub in the before block will prevent `File.read` from
  # running.
  let(:json_path) { Rails.root.join('spec', 'support', 'fixtures', 'canonical', 'sync', 'weapons.json') }

  let!(:json_data) { File.read(json_path) }

  before { allow(File).to receive(:read).and_return(json_data) }

  describe '::perform' do
    subject(:perform) { described_class.perform(preserve_existing_records) }

    context 'when preserve_existing_records is false' do
      let(:preserve_existing_records) { false }

      context 'when there are no existing canonical weapons in the database' do
        let(:syncer) { described_class.new(preserve_existing_records) }

        before do
          create(:enchantment, name: 'Frost Damage')
          create(:power, name: 'Blessing of the Stag Prince')
          allow(described_class).to receive(:new).and_return(syncer)
        end

        it 'instantiates itseslf' do
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records)
        end

        it 'populates the models from the JSON file' do
          expect { perform }
            .to change(Canonical::Weapon, :count).from(0).to(4)
        end

        it 'creates the associations to enchantments where they exist', :aggregate_failures do
          perform
          expect(Canonical::Weapon.find_by(item_code: '00034182').enchantments.length).to eq 0
          expect(Canonical::Weapon.find_by(item_code: '0005BF06').enchantments.length).to eq 1
          expect(Canonical::Weapon.find_by(item_code: '000139B4').enchantments.length).to eq 0
          expect(Canonical::Weapon.find_by(item_code: 'XX018ED5').enchantments.length).to eq 0
        end

        it 'creates the associations to powers where they exist', :aggregate_failures do
          perform
          expect(Canonical::Weapon.find_by(item_code: '00034182').powers.length).to eq 0
          expect(Canonical::Weapon.find_by(item_code: '0005BF06').powers.length).to eq 0
          expect(Canonical::Weapon.find_by(item_code: '000139B4').powers.length).to eq 0
          expect(Canonical::Weapon.find_by(item_code: 'XX018ED5').powers.length).to eq 1
        end
      end

      context 'when there are existing canonical weapon records in the database' do
        let!(:item_in_json) { create(:canonical_weapon, item_code: '0005BF06', base_damage: 13) }
        let!(:item_not_in_json) { create(:canonical_weapon, item_code: '12345678') }
        let(:syncer) { described_class.new(preserve_existing_records) }

        before do
          create(:enchantment, name: 'Frost Damage')
          create(:power, name: 'Blessing of the Stag Prince')
        end

        it 'instantiates itself' do
          allow(described_class).to receive(:new).and_return(syncer)
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records)
        end

        it 'updates models that were already in the database' do
          perform
          expect(item_in_json.reload.base_damage).to eq 18
        end

        it "removes models in the database that aren't in the JSON data" do
          perform
          expect(Canonical::Weapon.find_by(item_code: '12345678')).to be_nil
        end

        it 'adds new models to the database', :aggregate_failures do
          perform
          expect(Canonical::Weapon.find_by(item_code: '00034182')).to be_present
          expect(Canonical::Weapon.find_by(item_code: '000139B4')).to be_present
          expect(Canonical::Weapon.find_by(item_code: 'XX018ED5')).to be_present
        end

        it "removes associations that don't exist in the JSON data" do
          item_in_json.enchantments.create!(name: 'Raise Hell', add_on: 'dawnguard', enchantable_items: Enchantment::ENCHANTABLE_WEAPONS)
          perform
          expect(item_in_json.enchantments.find_by(name: 'Raise Hell')).to be_nil
        end

        it 'adds associations if they exist' do
          perform
          expect(item_in_json.enchantments.find_by(name: 'Frost Damage')).to be_present
        end
      end

      context 'when there are no enchantments in the database' do
        before { allow(Rails.logger).to receive(:error) }

        it "logs an error and doesn't create models", :aggregate_failures do
          expect { perform }
            .to raise_error(Canonical::Sync::PrerequisiteNotMetError)

          expect(Rails.logger).to have_received(:error).with('Prerequisite(s) not met: sync Enchantment, Power before canonical weapons')

          expect(Canonical::Weapon.count).to eq 0
        end
      end

      context 'when an association is missing' do
        before do
          # prevent it from erroring out, which it will do if there are no
          # enchantments/powers at all
          create(:enchantment)
          create(:power)
          allow(Rails.logger).to receive(:error).twice
        end

        it 'logs a validation error', :aggregate_failures do
          expect { perform }
            .to raise_error ActiveRecord::RecordInvalid

          expect(Rails.logger).to have_received(:error).with('Validation error saving associations for canonical weapon "0005BF06": Validation failed: Enchantment must exist')
        end
      end
    end

    context 'when preserve_existing_records is true' do
      let(:preserve_existing_records) { true }
      let(:syncer) { described_class.new(preserve_existing_records) }
      let!(:item_in_json) { create(:canonical_weapon, item_code: '0005BF06', base_damage: 13) }
      let!(:item_not_in_json) { create(:canonical_weapon, item_code: '12345678') }

      before do
        create(:enchantment, name: 'Frost Damage')
        create(:power, name: 'Blessing of the Stag Prince')
      end

      it 'instantiates itself' do
        allow(described_class).to receive(:new).and_return(syncer)
        perform
        expect(described_class).to have_received(:new).with(preserve_existing_records)
      end

      it 'updates models found in the JSON data' do
        perform
        expect(item_in_json.reload.base_damage).to eq 18
      end

      it 'adds models not already in the database', :aggregate_failures do
        perform
        expect(Canonical::Weapon.find_by(item_code: '00034182')).to be_present
        expect(Canonical::Weapon.find_by(item_code: '000139B4')).to be_present
        expect(Canonical::Weapon.find_by(item_code: 'XX018ED5')).to be_present
      end

      it "doesn't destroy models that aren't in the JSON data" do
        perform
        expect(item_not_in_json.reload).to be_present
      end

      it "doesn't destroy associations" do
        perform
        expect(item_in_json.reload.enchantments.find_by(name: 'Frost Damage')).to be_present
      end
    end

    describe 'error logging' do
      let(:preserve_existing_records) { false }

      context 'when an ActiveRecord::RecordInvalid error is raised' do
        let(:errored_model) { instance_double Canonical::Weapon, errors:, class: class_double(Canonical::Weapon, i18n_scope: :activerecord) }

        let(:errors) { double('errors', full_messages: ["Name can't be blank"]) }

        before do
          create(:enchantment)
          create(:power)

          allow_any_instance_of(Canonical::Weapon).to receive(:save!).and_raise(ActiveRecord::RecordInvalid, errored_model)
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(ActiveRecord::RecordInvalid)

          expect(Rails.logger).to have_received(:error).with("Error saving canonical weapon \"00034182\": Validation failed: Name can't be blank")
        end
      end

      context 'when another error is raised pertaining to a specific model' do
        before do
          create(:enchantment)
          create(:power)

          allow(Canonical::Weapon).to receive(:find_or_initialize_by).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger).to have_received(:error).with('Unexpected error StandardError saving canonical weapon "00034182": foobar')
        end
      end

      context 'when an error is raised not pertaining to a specific model' do
        before do
          create(:enchantment)
          create(:power)

          allow(Canonical::Weapon).to receive(:where).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger).to have_received(:error).with('Unexpected error StandardError while syncing canonical weapons: foobar')
        end
      end
    end
  end
end

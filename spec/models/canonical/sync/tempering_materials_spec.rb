# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Sync::TemperingMaterials do
  # Use let! because if we wait to evaluate these until we've run the
  # examples, the stub in the before block will prevent `File.read` from
  # running.
  let!(:json_data) { File.read(json_path) }
  let!(:json_path) { Rails.root.join('spec', 'support', 'fixtures', 'canonical', 'sync', 'tempering_materials.json') }

  before { allow(File).to receive(:read).and_return(json_data) }

  describe '::perform' do
    subject(:perform) { described_class.perform(preserve_existing_records) }

    context 'when prerequisite models exist' do
      before do
        # Create the temperable items that need to be present for join
        # models to be created
        create(:canonical_armor, name: 'Steel Boots of Strength', item_code: '000B509C')
        create(:canonical_weapon, name: 'Glass Dagger of Harvesting', item_code: '000BEEEE')
        create(:canonical_armor, name: 'Gloves of the Pugilist', item_code: '0010A06A')
        create(:canonical_weapon, name: "Miraak's Sword", item_code: 'XX039FB1')

        # Create the source materials that need to be present for join
        # models to be created
        create(:canonical_raw_material, name: 'Steel Ingot', item_code: '0005ACE5')
        create(:canonical_raw_material, name: 'Refined Malachite', item_code: '0005ADA1')
        create(:canonical_raw_material, name: 'Ebony Ingot', item_code: '0005AD9D')
        create(:canonical_raw_material, name: 'Leather', item_code: '000DB5D2')
        create(:canonical_raw_material, name: 'Leather Strips', item_code: '000800E4')
        create(:canonical_ingredient, name: 'Daedra Heart', item_code: '0003AD5B') \
      end

      context 'when preserve_existing_records is false' do
        let(:preserve_existing_records) { false }
        let(:syncer) { described_class.new(preserve_existing_records) }

        before { allow(described_class).to receive(:new).and_return(syncer) }

        it 'instantiates itself' do
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records)
        end

        context 'when there are no existing crafting material records in the database' do
          it 'populates the models from the JSON file' do
            expect { perform }
              .to change(Canonical::Material, :count)
                    .from(0)
                    .to(6)
          end

          it 'creates the correct associations', :aggregate_failures do
            perform
            expect(Canonical::Armor.find_by(item_code: '000B509C').tempering_materials.count).to eq 1
            expect(Canonical::Weapon.find_by(item_code: '000BEEEE').tempering_materials.count).to eq 1
            expect(Canonical::Armor.find_by(item_code: '0010A06A').tempering_materials.count).to eq 2
            expect(Canonical::Weapon.find_by(item_code: 'XX039FB1').tempering_materials.count).to eq 2
          end
        end

        context 'when there are existing tempering material records in the database' do
          let(:temperable) { Canonical::Armor.find_by(item_code: '000B509C') }

          before { create(:canonical_material, temperable:) }

          it 'removes existing records', :aggregate_failures do
            perform
            expect(temperable.reload.tempering_materials.count).to eq 1
            expect(temperable.tempering_materials.map(&:name)).to eq ['Steel Ingot']
          end
        end
      end

      context 'when preserve_existing_records is true' do
        let(:preserve_existing_records) { true }
        let(:temperable) { Canonical::Weapon.find_by(item_code: '000BEEEE') }

        before { create(:canonical_material, temperable:) }

        it 'keeps the existing records' do
          perform
          expect(temperable.reload.tempering_materials.count).to eq 2
        end
      end
    end

    context 'when prerequisite models do not exist' do
      let(:preserve_existing_records) { false }

      before { allow(Rails.logger).to receive(:error) }

      it 'raises an error', :aggregate_failures do
        expect { perform }
          .to raise_error(Canonical::Sync::PrerequisiteNotMetError)

        expect(Rails.logger).to have_received(:error).with('Prerequisite(s) not met: sync Canonical::Armor, Canonical::Weapon, Canonical::RawMaterial, Canonical::Ingredient before tempering materials')
      end
    end
  end
end

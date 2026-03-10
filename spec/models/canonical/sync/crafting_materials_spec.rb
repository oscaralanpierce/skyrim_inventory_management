# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Sync::CraftingMaterials do
  # Use let! because if we wait to evaluate these until we've run the
  # examples, the stub in the before block will prevent `File.read` from
  # running.
  let!(:json_data) { File.read(json_path) }
  let!(:json_path) do
    Rails.root.join(
      'spec',
      'support',
      'fixtures',
      'canonical',
      'sync',
      'crafting_materials.json',
    )
  end

  before do
    allow(File).to receive(:read).and_return(json_data)
  end

  describe '::perform' do
    subject(:perform) { described_class.perform(preserve_existing_records) }

    context 'when prerequisite models have been synced' do
      before do
        # Create the craftable items that need to be present for join
        # models to be created
        create(:canonical_armor, name: 'Shellbug Helmet', item_code: 'XX012E8A')
        create(:canonical_weapon, name: 'Nordic Bow', item_code: 'XX026232')
        create(:canonical_jewelry_item, name: 'Gold Emerald Ring', item_code: '000877CA')
        create(:canonical_armor, name: 'Bonemold Gauntlets', item_code: 'XX01CD94')
        create(:canonical_weapon, name: 'Enhanced Crossbow', item_code: 'XX00F19E')

        # Create the source materials that need to be present for join
        # models to be created
        create(:canonical_raw_material, name: 'Shellbug Chitin', item_code: 'XX0195AA')
        create(:canonical_raw_material, name: 'Iron Ingot', item_code: '0005ACE4')
        create(:canonical_raw_material, name: 'Steel Ingot', item_code: '0005ACE5')
        create(:canonical_raw_material, name: 'Quicksilver Ingot', item_code: '0005ADA0')
        create(:canonical_raw_material, name: 'Gold Ingot', item_code: '0005AD9E')
        create(:canonical_raw_material, name: 'Emerald', item_code: '00063B43')
        create(:canonical_raw_material, name: 'Netch Leather', item_code: 'XX01CD7C')
        create(:canonical_ingredient, name: 'Bone Meal', item_code: '00034CDD')
        create(:canonical_weapon, name: 'Crossbow', item_code: 'XX000801')
        create(:canonical_raw_material, name: 'Corundum Ingot', item_code: '0005AD93')
      end

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

        context 'when there are no existing crafting material records in the database' do
          it 'populates the models from the JSON file' do
            expect { perform }
              .to change(Canonical::Material, :count)
                    .from(0)
                    .to(11)
          end

          it 'creates the correct associations', :aggregate_failures do
            perform
            expect(Canonical::Armor.find_by(item_code: 'XX012E8A').crafting_materials.count).to eq(2)
            expect(Canonical::Weapon.find_by(item_code: 'XX026232').crafting_materials.count).to eq(2)
            expect(Canonical::JewelryItem.find_by(item_code: '000877CA').crafting_materials.count).to eq(2)
            expect(Canonical::Armor.find_by(item_code: 'XX01CD94').crafting_materials.count).to eq(3)
            expect(Canonical::Weapon.find_by(item_code: 'XX00F19E').crafting_materials.count).to eq(2)
          end
        end

        context 'when there are existing crafting material records in the database' do
          let(:craftable) { Canonical::Armor.find_by(item_code: 'XX012E8A') }

          before do
            create(
              :canonical_material,
              craftable:,
            )
          end

          it 'removes existing records', :aggregate_failures do
            perform
            expect(craftable.reload.crafting_materials.count).to eq(2)
            expect(craftable.crafting_materials.map(&:name)).to eq(['Shellbug Chitin', 'Iron Ingot'])
          end
        end
      end

      context 'when preserve_existing_records is true' do
        let(:preserve_existing_records) { true }
        let(:craftable) { Canonical::Weapon.find_by(item_code: 'XX00F19E') }

        before do
          create(
            :canonical_material,
            craftable:,
          )
        end

        it 'keeps the existing records' do
          perform
          expect(craftable.reload.crafting_materials.count).to eq(3)
        end
      end
    end

    context 'when one or more prerequisite models has not been synced' do
      let(:preserve_existing_records) { false }

      before do
        allow(Rails.logger).to receive(:error)
      end

      it 'raises an error', :aggregate_failures do
        expect { perform }
          .to raise_error(Canonical::Sync::PrerequisiteNotMetError)

        expect(Rails.logger)
          .to have_received(:error)
                .with('Prerequisite(s) not met: sync Canonical::Weapon, Canonical::Armor, Canonical::JewelryItem, Canonical::Ingredient, Canonical::RawMaterial before crafting materials')
      end
    end
  end
end

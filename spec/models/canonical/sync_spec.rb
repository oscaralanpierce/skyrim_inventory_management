# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Sync do
  describe 'perform' do
    context 'when the model is ":all"' do
      subject(:perform) { described_class.perform(model: :all, preserve_existing_records: false) }

      before do
        described_class::SYNCERS.each_value do |syncer|
          allow(syncer).to receive(:perform)
        end
      end

      it 'calls all the other syncers', :aggregate_failures do
        perform
        described_class::SYNCERS.each_value do |syncer|
          expect(syncer).to have_received(:perform).with(preserve_existing_records: false)
        end
      end
    end

    context 'when the model is ":alchemical_property"' do
      subject(:perform) { described_class.perform(model: :alchemical_property, preserve_existing_records: false) }

      before do
        allow(Canonical::Sync::AlchemicalProperties).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::AlchemicalProperties).to have_received(:perform).with(preserve_existing_records: false)
      end
    end

    context 'when the model is ":enchantment"' do
      subject(:perform) { described_class.perform(model: :enchantment, preserve_existing_records: true) }

      before do
        allow(Canonical::Sync::Enchantments).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Enchantments).to have_received(:perform).with(preserve_existing_records: true)
      end
    end

    context 'when the model is ":spell"' do
      subject(:perform) { described_class.perform(model: :spell, preserve_existing_records: false) }

      before do
        allow(Canonical::Sync::Spells).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Spells).to have_received(:perform).with(preserve_existing_records: false)
      end
    end

    context 'when the model is ":property"' do
      subject(:perform) { described_class.perform(model: :property, preserve_existing_records: false) }

      before do
        allow(Canonical::Sync::Properties).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Properties).to have_received(:perform).with(preserve_existing_records: false)
      end
    end

    context 'when the model is ":jewelry"' do
      subject(:perform) { described_class.perform(model: :jewelry, preserve_existing_records: true) }

      before do
        allow(Canonical::Sync::JewelryItems).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::JewelryItems).to have_received(:perform).with(preserve_existing_records: true)
      end
    end

    context 'when the model is ":clothing"' do
      subject(:perform) { described_class.perform(model: :clothing, preserve_existing_records: false) }

      before do
        allow(Canonical::Sync::ClothingItems).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::ClothingItems).to have_received(:perform).with(preserve_existing_records: false)
      end
    end

    context 'when the model is ":armor"' do
      subject(:perform) { described_class.perform(model: :armor, preserve_existing_records: true) }

      before do
        allow(Canonical::Sync::Armor).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Armor).to have_received(:perform).with(preserve_existing_records: true)
      end
    end

    context 'when the model is ":ingredient"' do
      subject(:perform) { described_class.perform(model: :ingredient, preserve_existing_records: true) }

      before do
        allow(Canonical::Sync::Ingredients).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Ingredients).to have_received(:perform).with(preserve_existing_records: true)
      end
    end

    context 'when the model is ":weapon"' do
      subject(:perform) { described_class.perform(model: :weapon, preserve_existing_records: true) }

      before do
        allow(Canonical::Sync::Weapons).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Weapons).to have_received(:perform).with(preserve_existing_records: true)
      end
    end

    context 'when the model is ":power"' do
      subject(:perform) { described_class.perform(model: :power, preserve_existing_records: true) }

      before do
        allow(Canonical::Sync::Powers).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Powers).to have_received(:perform).with(preserve_existing_records: true)
      end
    end

    context 'when the model is ":staff"' do
      subject(:perform) { described_class.perform(model: :staff, preserve_existing_records: true) }

      before do
        allow(Canonical::Sync::Staves).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Staves).to have_received(:perform).with(preserve_existing_records: true)
      end
    end

    context 'when the model is ":book"' do
      subject(:perform) { described_class.perform(model: :book, preserve_existing_records: false) }

      before do
        allow(Canonical::Sync::Books).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Books).to have_received(:perform).with(preserve_existing_records: false)
      end
    end

    context 'when the model is ":misc_item"' do
      subject(:perform) { described_class.perform(model: :misc_item, preserve_existing_records: true) }

      before do
        allow(Canonical::Sync::MiscItems).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::MiscItems).to have_received(:perform).with(preserve_existing_records: true)
      end
    end

    context 'when the model is ":potion"' do
      subject(:perform) { described_class.perform(model: :potion, preserve_existing_records: true) }

      before do
        allow(Canonical::Sync::Potions).to receive(:perform)
      end

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Potions).to have_received(:perform).with(preserve_existing_records: true)
      end
    end

    context 'when the item is ":crafting_material"' do
      subject(:perform) { described_class.perform(model: :crafting_material) }

      before do
        allow(Canonical::Sync::CraftingMaterials).to receive(:perform)
      end

      it 'calls ::perform on the correct syncer' do
        perform
        expect(Canonical::Sync::CraftingMaterials).to have_received(:perform)
      end
    end

    context 'when the item is ":tempering_material"' do
      subject(:perform) { described_class.perform(model: :tempering_material) }

      before do
        allow(Canonical::Sync::TemperingMaterials).to receive(:perform)
      end

      it 'calls ::perform on the correct syncer' do
        perform
        expect(Canonical::Sync::TemperingMaterials).to have_received(:perform)
      end
    end
  end
end

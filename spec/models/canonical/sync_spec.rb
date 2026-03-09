# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Sync do
  describe 'perform' do
    context 'when the model is ":all"' do
      subject(:perform) { described_class.perform(:all, false) }

      before { described_class::SYNCERS.each_value {|syncer| allow(syncer).to receive(:perform) } }

      it 'calls all the other syncers', :aggregate_failures do
        perform
        described_class::SYNCERS.each_value {|syncer| expect(syncer).to have_received(:perform).with(false) }
      end
    end

    context 'when the model is ":alchemical_property"' do
      subject(:perform) { described_class.perform(:alchemical_property, false) }

      before { allow(Canonical::Sync::AlchemicalProperties).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::AlchemicalProperties).to have_received(:perform).with(false)
      end
    end

    context 'when the model is ":enchantment"' do
      subject(:perform) { described_class.perform(:enchantment, true) }

      before { allow(Canonical::Sync::Enchantments).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Enchantments).to have_received(:perform).with(true)
      end
    end

    context 'when the model is ":spell"' do
      subject(:perform) { described_class.perform(:spell, false) }

      before { allow(Canonical::Sync::Spells).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Spells).to have_received(:perform).with(false)
      end
    end

    context 'when the model is ":property"' do
      subject(:perform) { described_class.perform(:property, false) }

      before { allow(Canonical::Sync::Properties).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Properties).to have_received(:perform).with(false)
      end
    end

    context 'when the model is ":jewelry"' do
      subject(:perform) { described_class.perform(:jewelry, true) }

      before { allow(Canonical::Sync::JewelryItems).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::JewelryItems).to have_received(:perform).with(true)
      end
    end

    context 'when the model is ":clothing"' do
      subject(:perform) { described_class.perform(:clothing, false) }

      before { allow(Canonical::Sync::ClothingItems).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::ClothingItems).to have_received(:perform).with(false)
      end
    end

    context 'when the model is ":armor"' do
      subject(:perform) { described_class.perform(:armor, true) }

      before { allow(Canonical::Sync::Armor).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Armor).to have_received(:perform).with(true)
      end
    end

    context 'when the model is ":ingredient"' do
      subject(:perform) { described_class.perform(:ingredient, true) }

      before { allow(Canonical::Sync::Ingredients).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Ingredients).to have_received(:perform).with(true)
      end
    end

    context 'when the model is ":weapon"' do
      subject(:perform) { described_class.perform(:weapon, true) }

      before { allow(Canonical::Sync::Weapons).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Weapons).to have_received(:perform).with(true)
      end
    end

    context 'when the model is ":power"' do
      subject(:perform) { described_class.perform(:power, true) }

      before { allow(Canonical::Sync::Powers).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Powers).to have_received(:perform).with(true)
      end
    end

    context 'when the model is ":staff"' do
      subject(:perform) { described_class.perform(:staff, true) }

      before { allow(Canonical::Sync::Staves).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Staves).to have_received(:perform).with(true)
      end
    end

    context 'when the model is ":book"' do
      subject(:perform) { described_class.perform(:book, false) }

      before { allow(Canonical::Sync::Books).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Books).to have_received(:perform).with(false)
      end
    end

    context 'when the model is ":misc_item"' do
      subject(:perform) { described_class.perform(:misc_item, true) }

      before { allow(Canonical::Sync::MiscItems).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::MiscItems).to have_received(:perform).with(true)
      end
    end

    context 'when the model is ":potion"' do
      subject(:perform) { described_class.perform(:potion, true) }

      before { allow(Canonical::Sync::Potions).to receive(:perform) }

      it 'calls #perform on the correct syncer' do
        perform
        expect(Canonical::Sync::Potions).to have_received(:perform).with(true)
      end
    end

    context 'when the item is ":crafting_material"' do
      subject(:perform) { described_class.perform(:crafting_material) }

      before { allow(Canonical::Sync::CraftingMaterials).to receive(:perform) }

      it 'calls ::perform on the correct syncer' do
        perform
        expect(Canonical::Sync::CraftingMaterials).to have_received(:perform)
      end
    end

    context 'when the item is ":tempering_material"' do
      subject(:perform) { described_class.perform(:tempering_material) }

      before { allow(Canonical::Sync::TemperingMaterials).to receive(:perform) }

      it 'calls ::perform on the correct syncer' do
        perform
        expect(Canonical::Sync::TemperingMaterials).to have_received(:perform)
      end
    end
  end
end

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::RawMaterial, type: :model do
  describe 'validations' do
    subject(:validate) { material.validate }

    let(:material) { build(:canonical_raw_material) }

    describe 'name' do
      it 'is invalid without a name' do
        material.name = nil
        validate
        expect(material.errors[:name]).to include "can't be blank"
      end
    end

    describe 'item_code' do
      it 'is invalid without an item code' do
        material.item_code = nil
        validate
        expect(material.errors[:item_code]).to include "can't be blank"
      end

      it 'is invalid with a duplicate item code' do
        create(:canonical_raw_material, item_code: material.item_code)
        validate
        expect(material.errors[:item_code]).to include 'must be unique'
      end
    end

    describe 'unit_weight' do
      it 'is invalid without a unit weight' do
        material.unit_weight = nil
        validate
        expect(material.errors[:unit_weight]).to include "can't be blank"
      end

      it 'is invalid with a non-numeric unit weight' do
        material.unit_weight = 'bar'
        validate
        expect(material.errors[:unit_weight]).to include 'is not a number'
      end

      it 'is invalid without a negative unit weight' do
        material.unit_weight = -4.0
        validate
        expect(material.errors[:unit_weight]).to include 'must be greater than or equal to 0'
      end
    end

    describe 'add_on' do
      it "can't be blank" do
        material.add_on = nil
        validate
        expect(material.errors[:add_on]).to include "can't be blank"
      end

      it 'must be a supported add-on' do
        material.add_on = 'fishing'
        validate
        expect(material.errors[:add_on]).to include 'must be a SIM-supported add-on or DLC'
      end
    end
  end

  describe 'default behavior' do
    it 'upcases item codes' do
      material = create(:canonical_raw_material, item_code: 'abc123')
      expect(material.reload.item_code).to eq 'ABC123'
    end
  end

  describe 'associations' do
    describe '#craftable_weapons' do
      subject(:craftable_weapons) { raw_material.craftable_weapons }

      let!(:raw_material) { create(:canonical_raw_material) }
      let!(:craftables) { create_list(:canonical_weapon, 2) }

      before do
        create(:canonical_material, craftable: craftables.first, source_material: raw_material)
        create(:canonical_material, craftable: craftables.last, source_material: raw_material)
        create(:canonical_material, temperable: create(:canonical_weapon), source_material: raw_material)
        raw_material.reload
      end

      it 'returns only associated craftable weapons' do
        expect(craftable_weapons).to contain_exactly(*craftables)
      end
    end

    describe '#temperable_weapons' do
      subject(:temperable_weapons) { raw_material.temperable_weapons }

      let!(:raw_material) { create(:canonical_raw_material) }
      let!(:temperables) { create_list(:canonical_weapon, 2) }

      before do
        create(:canonical_material, temperable: temperables.first, source_material: raw_material)
        create(:canonical_material, temperable: temperables.last, source_material: raw_material)
        create(:canonical_material, craftable: create(:canonical_weapon), source_material: raw_material)

        raw_material.reload
      end

      it 'returns only associated temperable weapons' do
        expect(temperable_weapons).to contain_exactly(*temperables)
      end
    end

    describe '#craftable_armors' do
      subject(:craftable_armors) { raw_material.craftable_armors }

      let!(:raw_material) { create(:canonical_raw_material) }
      let!(:craftables) { create_list(:canonical_armor, 2) }

      before do
        create(:canonical_material, craftable: craftables.first, source_material: raw_material)
        create(:canonical_material, craftable: craftables.last, source_material: raw_material)
        create(:canonical_material, temperable: create(:canonical_armor), source_material: raw_material)
        raw_material.reload
      end

      it 'returns only associated craftable armors' do
        expect(craftable_armors).to contain_exactly(*craftables)
      end
    end

    describe '#temperable_armors' do
      subject(:temperable_armors) { raw_material.temperable_armors }

      let!(:raw_material) { create(:canonical_raw_material) }
      let!(:temperables) { create_list(:canonical_armor, 2) }

      before do
        create(:canonical_material, temperable: temperables.first, source_material: raw_material)
        create(:canonical_material, temperable: temperables.last, source_material: raw_material)
        create(:canonical_material, craftable: create(:canonical_armor), source_material: raw_material)
        raw_material.reload
      end

      it 'returns only associated temperable armors' do
        expect(temperable_armors).to contain_exactly(*temperables)
      end
    end

    describe '#jewelry_items' do
      subject(:jewelry_items) { raw_material.jewelry_items }

      let!(:raw_material) { create(:canonical_raw_material) }
      let!(:craftables) { create_list(:canonical_jewelry_item, 2) }

      before do
        create(:canonical_material, craftable: craftables.first, source_material: raw_material)
        create(:canonical_material, craftable: craftables.last, source_material: raw_material)
        raw_material.reload
      end

      it 'returns only associated craftable jewelry items' do
        expect(jewelry_items).to contain_exactly(*craftables)
      end
    end

    describe '#craftable_items' do
      subject(:craftable_items) { source_material.craftable_items }

      let(:source_material) { create(:canonical_raw_material) }

      let!(:canonical_materials) { [create(:canonical_material, source_material:, craftable: create(:canonical_armor)), create(:canonical_material, source_material:, craftable: create(:canonical_weapon)), create(:canonical_material, source_material:, craftable: create(:canonical_jewelry_item))] }

      before { source_material.reload }

      it 'includes all craftable items regardless of class' do
        craftables = canonical_materials.map(&:craftable)

        expect(craftable_items).to contain_exactly(*craftables)
      end
    end

    describe '#temperable_items' do
      subject(:temperable_items) { source_material.temperable_items }

      let(:source_material) { create(:canonical_raw_material) }

      let!(:canonical_materials) { [create(:canonical_material, source_material:, temperable: create(:canonical_armor)), create(:canonical_material, source_material:, temperable: create(:canonical_weapon))] }

      before { source_material.reload }

      it 'includes all temperable items regardless of class' do
        temperables = canonical_materials.map(&:temperable)

        expect(temperable_items).to contain_exactly(*temperables)
      end
    end
  end

  describe 'class methods' do
    describe '::unique_identifier' do
      it 'returns :item_code' do
        expect(described_class.unique_identifier).to eq :item_code
      end
    end
  end
end

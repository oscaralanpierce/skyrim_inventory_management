# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Canonical::Sync::Ingredients do
  # Use let! because if we wait to evaluate these until we've run the
  # examples, the stub in the before block will prevent `File.read` from
  # running.
  let(:json_path) { Rails.root.join('spec', 'support', 'fixtures', 'canonical', 'sync', 'ingredients.json') }
  let!(:json_data) { File.read(json_path) }

  let(:alchemical_property_names) do
    # There are a shitload of these (16) so better to just take the names from
    # the JSON instead of listing them all out.
    names = JSON
              .parse(json_data, symbolize_names: true)
              .map {|data| data[:alchemical_properties].pluck(:name) }

    names.flatten!.uniq!
  end

  before do
    allow(File).to receive(:read).and_return(json_data)
  end

  describe '::perform' do
    subject(:perform) { described_class.perform(preserve_existing_records) }

    context 'when preserve_existing_records is false' do
      let(:preserve_existing_records) { false }

      context 'when there are no existing canonical ingredients in the database' do
        let(:syncer) { described_class.new(preserve_existing_records) }

        before do
          alchemical_property_names.each {|name| create(:alchemical_property, name:) }
        end

        it 'instantiates itseslf' do
          allow(described_class).to receive(:new).and_return(syncer)
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records)
        end

        it 'populates the models from the JSON file' do
          expect { perform }
            .to change(Canonical::Ingredient, :count).from(0).to(4)
        end

        it 'creates the associations to alchemical properties', :aggregate_failures do
          perform
          expect(Canonical::Ingredient.find_by(item_code: '00106E1B').alchemical_properties.length).to eq(4)
          expect(Canonical::Ingredient.find_by(item_code: 'XX01CD71').alchemical_properties.length).to eq(4)
          expect(Canonical::Ingredient.find_by(item_code: '00034D31').alchemical_properties.length).to eq(4)
          expect(Canonical::Ingredient.find_by(item_code: '0003AD5E').alchemical_properties.length).to eq(4)
        end
      end

      context 'when there are existing canonical ingredient records in the database' do
        let!(:item_in_json) { create(:canonical_ingredient, item_code: '00106E1B', unit_weight: 1.2) }
        let!(:item_not_in_json) { create(:canonical_ingredient, item_code: '12345678') }
        let(:syncer) { described_class.new(preserve_existing_records) }

        before do
          alchemical_property_names.each {|name| create(:alchemical_property, name:) }
        end

        it 'instantiates itself' do
          allow(described_class).to receive(:new).and_return(syncer)
          perform
          expect(described_class).to have_received(:new).with(preserve_existing_records)
        end

        it 'updates models that were already in the database' do
          perform
          expect(item_in_json.reload.unit_weight).to eq(0.5)
        end

        it "removes models in the database that aren't in the JSON data" do
          perform
          expect(Canonical::Ingredient.find_by(item_code: '12345678')).to be_nil
        end

        it 'adds new models to the database', :aggregate_failures do
          perform
          expect(Canonical::Ingredient.find_by(item_code: 'XX01CD71')).to be_present
          expect(Canonical::Ingredient.find_by(item_code: '00034D31')).to be_present
          expect(Canonical::Ingredient.find_by(item_code: '0003AD5E')).to be_present
        end

        it "removes alchemical properties that don't exist in the JSON data" do
          item_in_json.canonical_ingredients_alchemical_properties.create!(
            alchemical_property: create(:alchemical_property, name: 'Fortify Awesomeness'),
            priority: 1,
          )

          perform
          expect(item_in_json.alchemical_properties.find_by(name: 'Fortify Awesomeness')).to be_nil
        end

        it 'adds alchemical properties' do
          perform
          expect(item_in_json.alchemical_properties.pluck(:name))
            .to contain_exactly('Weakness to Frost', 'Fortify Sneak', 'Weakness to Poison', 'Fortify Restoration')
        end
      end

      context 'when there are no alchemical properties in the database' do
        before do
          allow(Rails.logger).to receive(:error)
        end

        it "logs an error and doesn't create models", :aggregate_failures do
          expect { perform }
            .to raise_error(Canonical::Sync::PrerequisiteNotMetError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Prerequisite(s) not met: sync AlchemicalProperty before canonical ingredients')

          expect(Canonical::Ingredient.count).to eq(0)
        end
      end

      context 'when an alchemical property is missing' do
        before do
          # prevent it from erroring out, which it will do if there are no
          # enchantments all
          create(:alchemical_property)
          allow(Rails.logger).to receive(:error).twice
        end

        it 'logs a validation error', :aggregate_failures do
          expect { perform }
            .to raise_error(ActiveRecord::RecordInvalid)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Validation error saving associations for canonical ingredient "00106E1B": Validation failed: Alchemical property must exist')
        end
      end
    end

    context 'when preserve_existing_records is true' do
      let(:preserve_existing_records) { true }
      let(:syncer) { described_class.new(preserve_existing_records) }
      let!(:item_in_json) { create(:canonical_ingredient, item_code: '00106E1B', unit_weight: 1.2) }
      let!(:item_not_in_json) { create(:canonical_ingredient, item_code: '12345678') }

      before do
        alchemical_property_names.each {|name| create(:alchemical_property, name:) }

        create(
          :canonical_ingredients_alchemical_property,
          ingredient: item_in_json,
          alchemical_property: create(:alchemical_property, name: 'Fortify Awesomeness'),
          priority: 1,
        )

        allow(Rails.logger).to receive(:warn)
      end

      it 'instantiates itself' do
        allow(described_class).to receive(:new).and_return(syncer)
        perform
        expect(described_class).to have_received(:new).with(preserve_existing_records)
      end

      it 'updates models found in the JSON data' do
        perform
        expect(item_in_json.reload.unit_weight).to eq(0.5)
      end

      it 'adds models not already in the database', :aggregate_failures do
        perform
        expect(Canonical::Ingredient.find_by(item_code: 'XX01CD71')).to be_present
        expect(Canonical::Ingredient.find_by(item_code: '00034D31')).to be_present
        expect(Canonical::Ingredient.find_by(item_code: '0003AD5E')).to be_present
      end

      it "doesn't destroy models that aren't in the JSON data" do
        perform
        expect(item_not_in_json.reload).to be_present
      end

      it 'destroys associations (unlike other syncers)' do
        perform
        expect(item_in_json.reload.alchemical_properties.where(name: 'Fortify Awesomeness')).to be_empty
      end

      it 'logs a warning' do
        perform

        expect(Rails.logger)
          .to have_received(:warn)
                .with('preserve_existing_records mode does not preserve associations for canonical ingredients')
      end
    end

    describe 'error logging' do
      let(:preserve_existing_records) { false }

      context 'when an ActiveRecord::RecordInvalid error is raised' do
        let(:errored_model) do
          instance_double Canonical::Ingredient,
                          errors:,
                          class: class_double(Canonical::Ingredient, i18n_scope: :activerecord)
        end

        let(:errors) { double('errors', full_messages: ["Name can't be blank"]) }

        before do
          create(:alchemical_property)

          allow_any_instance_of(Canonical::Ingredient)
            .to receive(:save!)
                  .and_raise(ActiveRecord::RecordInvalid, errored_model)
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(ActiveRecord::RecordInvalid)

          expect(Rails.logger)
            .to have_received(:error)
                  .with("Error saving canonical ingredient \"00106E1B\": Validation failed: Name can't be blank")
        end
      end

      context 'when another error is raised pertaining to a specific model' do
        before do
          create(:alchemical_property)

          allow(Canonical::Ingredient).to receive(:find_or_initialize_by).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Unexpected error StandardError saving canonical ingredient "00106E1B": foobar')
        end
      end

      context 'when an error is raised not pertaining to a specific model' do
        before do
          create(:alchemical_property)

          allow(Canonical::Ingredient).to receive(:where).and_raise(StandardError, 'foobar')
          allow(Rails.logger).to receive(:error)
        end

        it 'logs and reraises the error', :aggregate_failures do
          expect { perform }
            .to raise_error(StandardError)

          expect(Rails.logger)
            .to have_received(:error)
                  .with('Unexpected error StandardError while syncing canonical ingredients: foobar')
        end
      end
    end
  end
end

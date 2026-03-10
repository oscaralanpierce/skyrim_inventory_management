# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Potion, type: :model do
  describe 'validations' do
    subject(:validate) { potion.validate }

    let(:potion) { build(:potion) }

    before do
      create(:alchemical_property, name: 'Fortify Destruction', effect_type: 'potion')
    end

    describe '#name' do
      it "can't be blank" do
        potion.name = nil
        validate
        expect(potion.errors[:name]).to include("can't be blank")
      end
    end

    describe '#unit_weight' do
      it 'can be blank' do
        potion.unit_weight = nil
        validate
        expect(potion.errors[:unit_weight]).to be_empty
      end

      it 'must be at least 0' do
        potion.unit_weight = -0.5
        validate
        expect(potion.errors[:unit_weight]).to include('must be greater than or equal to 0')
      end
    end

    describe '#canonical_potion' do
      let(:potion) { build(:potion, canonical_potion:, game:) }
      let(:game) { create(:game) }

      context 'when the canonical potion is not unique' do
        let(:canonical_potion) { create(:canonical_potion) }

        before do
          create_list(
            :potion,
            3,
            canonical_potion:,
            game:,
          )
        end

        it 'is valid' do
          expect(potion).to be_valid
        end
      end

      context 'when the canonical potion is unique' do
        let(:canonical_potion) do
          create(
            :canonical_potion,
            max_quantity: 1,
            unique_item: true,
            rare_item: true,
          )
        end

        context 'when there are no other non-canonical matches' do
          it 'is valid' do
            expect(potion).to be_valid
          end
        end

        context 'when there is another match for a different game' do
          before do
            create(:potion, canonical_potion:)
          end

          it 'is valid' do
            expect(potion).to be_valid
          end
        end

        context 'when there is another match for the same game' do
          before do
            create(:potion, canonical_potion:, game:)
          end

          it 'is invalid' do
            validate
            expect(potion.errors[:base]).to include('is a duplicate of a unique in-game item')
          end
        end
      end
    end

    describe 'player-created potions and poisons' do
      before do
        data = JSON.parse(
          File.read(
            Rails.root.join(
              'spec',
              'support',
              'fixtures',
              'canonical',
              'sync',
              'alchemical_properties.json',
            ),
          ),
          symbolize_names: true,
        )

        data.each do |object|
          AlchemicalProperty.create!(object[:attributes])
        rescue ActiveRecord::RecordInvalid
          next
        end
      end

      context 'when the potion has a valid name' do
        let(:potion) { build(:potion, name: 'pOiSoN Of dAmAgE hEaLtH') }

        it 'is valid' do
          expect(potion).to be_valid
        end

        it 'titlecases the name' do
          expect { validate }
            .to change(potion, :name)
                  .to('Poison of Damage Health')
        end
      end

      context 'when the name is invalid' do
        let(:potion) { build(:potion, name: 'Potion of Kickassery') }

        it 'adds an error' do
          validate
          expect(potion.errors[:name]).to include('must be a valid potion or poison name')
        end
      end
    end
  end

  describe '#canonical_model' do
    subject(:canonical_model) { potion.canonical_model }

    context 'when there is a canonical model assigned' do
      let(:potion) { create(:potion, :with_matching_canonical) }

      it 'returns the canonical potion' do
        expect(canonical_model).to eq(potion.canonical_potion)
      end
    end

    context 'when there is no canonical model assigned' do
      let(:potion) { create(:potion) }

      before do
        create_list(:canonical_potion, 2)
      end

      it 'returns nil' do
        expect(canonical_model).to be_nil
      end
    end
  end

  describe '#canonical_models' do
    subject(:canonical_models) { potion.canonical_models }

    context 'when only the name has to match' do
      let(:potion) { build(:potion, name: 'Potion of Healing') }

      let!(:matching_canonicals) do
        create_list(
          :canonical_potion,
          3,
          name: 'potion of healing',
        )
      end

      before do
        create(:canonical_potion)
      end

      it 'matches case-insensitively' do
        expect(canonical_models).to contain_exactly(*matching_canonicals)
      end
    end

    context 'when there are magical effects defined' do
      let(:potion) { build(:potion, name: 'Potion of Healing', magical_effects: 'foobar') }

      let!(:matching_canonicals) do
        create_list(
          :canonical_potion,
          3,
          name: 'potion of healing',
          magical_effects: 'Foobar',
        )
      end

      before do
        create(:canonical_potion, name: 'potion of healing', magical_effects: nil)
      end

      it 'returns all matching canonicals' do
        expect(canonical_models).to contain_exactly(*matching_canonicals)
      end
    end

    context 'when there are no matches' do
      let(:potion) { build(:potion, name: 'Deadly Poison', magical_effects: 'foo') }

      before do
        create(:canonical_potion, name: 'Deadly Poison')
      end

      it 'is empty' do
        expect(canonical_models).to be_empty
      end
    end

    context 'when the match changes' do
      let(:potion) { create(:potion, :with_matching_canonical) }

      let!(:new_canonical) do
        create(
          :canonical_potion,
          name: 'Elixir of Light Feet',
        )
      end

      it 'returns the canonical that matches the new attributes' do
        potion.name = 'elixir of light feet'

        expect(canonical_models).to contain_exactly(new_canonical)
      end
    end

    context 'when there is no longer a match after attributes changed' do
      let(:potion) { create(:potion, :with_matching_canonical) }

      it 'returns an empty ActiveRecord relation', :aggregate_failures do
        potion.name = 'My Special Potion'

        expect(canonical_models).to be_an(ActiveRecord::Relation)
        expect(canonical_models).to be_empty
      end
    end

    context 'when there are alchemical properties' do
      let(:potion) { create(:potion, name: 'Foo') }

      context 'when the potion has one alchemical property' do
        context 'when strength and duration are not defined' do
          let!(:canonical_potions) { create_list(:canonical_potion, 3, name: 'Foo') }

          let!(:join_model) do
            create(
              :potions_alchemical_property,
              potion:,
              strength: nil,
              duration: nil,
            )
          end

          before do
            create(
              :canonical_potions_alchemical_property,
              potion: canonical_potions.first,
              alchemical_property: join_model.alchemical_property,
              strength: 5,
              duration: nil,
            )

            create(
              :canonical_potions_alchemical_property,
              potion: canonical_potions.second,
              strength: nil,
              duration: nil,
            )

            create(
              :canonical_potions_alchemical_property,
              potion: canonical_potions.last,
              alchemical_property: join_model.alchemical_property,
              strength: nil,
              duration: nil,
            )

            potion.reload
          end

          it 'includes only matching models whose association strength and duration are also nil' do
            expect(canonical_models).to contain_exactly(canonical_potions.last)
          end
        end

        context 'when strength is defined but not duration' do
          let!(:canonical_potions) { create_list(:canonical_potion, 2, name: 'Foo') }

          let!(:join_model) do
            create(
              :potions_alchemical_property,
              potion:,
              strength: 16,
              duration: nil,
            )
          end

          before do
            create(
              :canonical_potions_alchemical_property,
              potion: canonical_potions.first,
              alchemical_property: join_model.alchemical_property,
              strength: 16,
              duration: 30,
            )

            create(
              :canonical_potions_alchemical_property,
              potion: canonical_potions.last,
              alchemical_property: join_model.alchemical_property,
              strength: 16,
              duration: nil,
            )

            potion.reload
          end

          it 'includes only models whose association duration is also nil' do
            expect(canonical_models).to contain_exactly(canonical_potions.last)
          end
        end

        context 'when duration is defined but not strength' do
          let!(:canonical_potions) { create_list(:canonical_potion, 2, name: 'Foo') }

          let!(:join_model) do
            create(
              :potions_alchemical_property,
              potion:,
              strength: nil,
              duration: 30,
            )
          end

          before do
            create(
              :canonical_potions_alchemical_property,
              potion: canonical_potions.first,
              alchemical_property: join_model.alchemical_property,
              strength: nil,
              duration: 30,
            )

            create(
              :canonical_potions_alchemical_property,
              potion: canonical_potions.last,
              alchemical_property: join_model.alchemical_property,
              strength: 16,
              duration: 30,
            )

            potion.reload
          end

          it 'includes only models whose association duration is also nil' do
            expect(canonical_models).to contain_exactly(canonical_potions.first)
          end
        end

        context 'when both strength and duration are defined' do
          let!(:canonical_potions) { create_list(:canonical_potion, 2, name: 'Foo') }

          let!(:join_model) do
            create(
              :potions_alchemical_property,
              potion:,
              strength: 12,
              duration: 30,
            )
          end

          before do
            create(
              :canonical_potions_alchemical_property,
              potion: canonical_potions.first,
              alchemical_property: join_model.alchemical_property,
              strength: 12,
              duration: 30,
            )

            create(
              :canonical_potions_alchemical_property,
              potion: canonical_potions.last,
              alchemical_property: join_model.alchemical_property,
              strength: 16,
              duration: 30,
            )

            potion.reload
          end

          it 'includes only models that fully match' do
            expect(canonical_models).to contain_exactly(canonical_potions.first)
          end
        end
      end

      context 'when the potion has multiple alchemical properties' do
        let!(:canonical_potions) { create_list(:canonical_potion, 4, name: 'foo') }

        let!(:join_models) do
          [
            create(
              :potions_alchemical_property,
              potion:,
              strength: 5,
              duration: 20,
            ),
            create(
              :potions_alchemical_property,
              potion:,
              strength: nil,
              duration: 60,
            ),
          ]
        end

        before do
          # The first canonical potion has one alchemical property that matches,
          # but shouldn't show up in the results since it doesn't have both.
          create(
            :canonical_potions_alchemical_property,
            potion: canonical_potions.first,
            alchemical_property: join_models.first.alchemical_property,
            strength: 5,
            duration: 20,
          )

          # The second canonical potion has multiple alchemical properties
          # but shouldn't show up in results because only one matches the
          # strength and duration
          create(
            :canonical_potions_alchemical_property,
            potion: canonical_potions.second,
            alchemical_property: join_models.first.alchemical_property,
            strength: 5,
            duration: 20,
          )
          create(
            :canonical_potions_alchemical_property,
            potion: canonical_potions.second,
            alchemical_property: join_models.last.alchemical_property,
            strength: 15,
            duration: nil,
          )

          # The third canonical potion has exact matching alchemical
          # properties - it should show up in results
          create(
            :canonical_potions_alchemical_property,
            potion: canonical_potions.third,
            alchemical_property: join_models.first.alchemical_property,
            strength: 5,
            duration: 20,
          )
          create(
            :canonical_potions_alchemical_property,
            potion: canonical_potions.third,
            alchemical_property: join_models.second.alchemical_property,
            strength: nil,
            duration: 60,
          )

          # The fourth canonical potion has both alchemical properties that
          # match as well as a third one - that's OK and it should be included
          # in the results too
          create(
            :canonical_potions_alchemical_property,
            potion: canonical_potions.last,
            alchemical_property: join_models.first.alchemical_property,
            strength: 5,
            duration: 20,
          )
          create(
            :canonical_potions_alchemical_property,
            potion: canonical_potions.last,
            alchemical_property: join_models.second.alchemical_property,
            strength: nil,
            duration: 60,
          )
          create(:canonical_potions_alchemical_property, potion: canonical_potions.last)

          potion.alchemical_properties.reload
          canonical_potions.each {|canonical_potion| canonical_potion.alchemical_properties.reload }
        end

        it 'includes the canonical models that fully match' do
          expect(canonical_models).to contain_exactly(canonical_potions.third, canonical_potions.last)
        end
      end

      context 'when there are automatically added alchemical properties' do
        let(:potion) { create(:potion) }
        let(:shared_property) { create(:alchemical_property) }

        let!(:matching_canonicals) do
          create_list(
            :canonical_potion,
            2,
          )
        end

        before do
          create(
            :canonical_potions_alchemical_property,
            potion: matching_canonicals.first,
            alchemical_property: shared_property,
          )

          create(
            :canonical_potions_alchemical_property,
            potion: matching_canonicals.last,
            alchemical_property: shared_property,
          )

          create(:canonical_potions_alchemical_property, potion: matching_canonicals.first)
          create(:canonical_potions_alchemical_property, potion: matching_canonicals.last)

          matching_canonicals.each do |canonical|
            canonical.canonical_potions_alchemical_properties.reload
            canonical.alchemical_properties.reload
          end

          create(
            :potions_alchemical_property,
            potion:,
            alchemical_property: shared_property,
            added_automatically: false,
          )

          create(
            :potions_alchemical_property,
            potion:,
            alchemical_property: matching_canonicals.first.alchemical_properties.last,
            added_automatically: true,
          )

          potion.potions_alchemical_properties.reload
          potion.alchemical_properties.reload
        end

        it 'matches only based on manually added alchemical properties' do
          expect(canonical_models).to contain_exactly(*matching_canonicals)
        end
      end
    end
  end

  describe '::before_validation' do
    subject(:validate) { potion.validate }

    let(:potion) { build(:potion) }

    context 'when there is a matching canonical potion' do
      let!(:matching_canonical) { create(:canonical_potion, name: potion.name.downcase, magical_effects: 'Foo') }

      it 'sets the canonical_potion' do
        validate
        expect(potion.canonical_potion).to eq(matching_canonical)
      end

      it 'sets the name, unit weight, and magical effects', :aggregate_failures do
        validate
        expect(potion.name).to eq(matching_canonical.name)
        expect(potion.unit_weight).to eq(matching_canonical.unit_weight)
        expect(potion.magical_effects).to eq(matching_canonical.magical_effects)
      end
    end

    context 'when there are multiple matching canonical potions' do
      let!(:matching_canonicals) { create_list(:canonical_potion, 2, name: potion.name.downcase) }

      it "doesn't set the canonical_potion" do
        validate
        expect(potion.canonical_potion).to be_nil
      end

      it "doesn't change the name" do
        expect { validate }
          .not_to change(potion, :name)
      end

      it "doesn't change the unit_weight" do
        expect { validate }
          .not_to change(potion, :unit_weight)
      end
    end

    context 'when there is no matching canonical potion' do
      it "doesn't set the canonical potion" do
        validate
        expect(potion.canonical_potion).to be_nil
      end
    end

    context 'when updating in-game item attributes' do
      let(:potion) { create(:potion, :with_matching_canonical) }

      before do
        create(
          :potions_alchemical_property,
          potion:,
          added_automatically: false,
        )

        potion.potions_alchemical_properties.reload
      end

      context 'when the update changes the canonical association' do
        let!(:new_canonical) do
          create(
            :canonical_potion,
            name: 'My Special Potion',
          )
        end

        before do
          create(
            :canonical_potions_alchemical_property,
            potion: new_canonical,
            alchemical_property: potion.potions_alchemical_properties.added_manually.first.alchemical_property,
          )

          new_canonical.canonical_potions_alchemical_properties.reload
        end

        it 'updates the canonical association' do
          potion.name = 'My Special Potion'

          expect { validate }
            .to change(potion, :canonical_potion)
                  .to(new_canonical)
        end

        it 'updates attributes' do
          potion.name = 'my special potion'

          validate

          expect(potion.name).to eq('My Special Potion')
        end

        it 'removes automatically added alchemical properties', :aggregate_failures do
          potion.name = 'my special potion'

          validate
          potion.potions_alchemical_properties.reload

          expect(potion.potions_alchemical_properties.count).to eq(1)
          expect(potion.potions_alchemical_properties.pluck(:added_automatically)).to be_all(false)
        end
      end

      context 'when the update results in an ambiguous match' do
        before do
          create_list(
            :canonical_potion,
            2,
            name: 'My Special Potion',
          )
        end

        it 'removes the associated canonical potion' do
          potion.name = 'My Special Potion'

          expect { validate }
            .to change(potion, :canonical_potion)
                  .to(nil)
        end

        it "doesn't update attributes" do
          potion.name = 'my special potion'

          validate

          expect(potion.name).to eq('my special potion')
        end

        it 'removes automatically-added alchemical properties', :aggregate_failures do
          potion.name = 'my special potion'

          validate
          potion.potions_alchemical_properties.reload

          expect(potion.potions_alchemical_properties.count).to eq(1)
          expect(potion.potions_alchemical_properties.pluck(:added_automatically)).to be_all(false)
        end
      end

      context 'when the update results in no canonical matches' do
        it 'sets the canonical potion to nil' do
          potion.name = 'My Special Potion'

          expect { validate }
            .to change(potion, :canonical_potion)
                  .to(nil)
        end

        it 'removes automatically-added alchemical properties', :aggregate_failures do
          potion.name = 'my special potion'

          validate
          potion.potions_alchemical_properties.reload

          expect(potion.potions_alchemical_properties.count).to eq(1)
          expect(potion.potions_alchemical_properties.pluck(:added_automatically)).to be_all(false)
        end
      end
    end
  end
end

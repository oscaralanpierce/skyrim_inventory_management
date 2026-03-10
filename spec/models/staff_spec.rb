# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Staff, type: :model do
  describe 'validations' do
    subject(:validate) { staff.validate }

    let(:staff) { build(:staff) }

    describe '#name' do
      it 'is invalid without a name' do
        staff.name = nil
        validate
        expect(staff.errors[:name]).to include("can't be blank")
      end
    end

    describe '#unit_weight' do
      it 'is invalid with a negative unit weight' do
        staff.unit_weight = -2
        validate
        expect(staff.errors[:unit_weight]).to include('must be greater than or equal to 0')
      end

      it 'can be nil' do
        staff.unit_weight = nil
        validate
        expect(staff.errors[:unit_weight]).to be_empty
      end
    end

    describe '#canonical_staff' do
      let(:staff) { build(:staff, canonical_staff:, game:) }
      let(:game) { create(:game) }

      context 'when the canonical staff is not unique' do
        let(:canonical_staff) { create(:canonical_staff) }

        before do
          create_list(
            :staff,
            3,
            canonical_staff:,
            game:,
          )
        end

        it 'is valid' do
          expect(staff).to be_valid
        end
      end

      context 'when the canonical staff is unique' do
        let(:canonical_staff) do
          create(
            :canonical_staff,
            max_quantity: 1,
            unique_item: true,
            rare_item: true,
          )
        end

        context 'when there are no other matches for the canonical staff' do
          it 'is valid' do
            expect(staff).to be_valid
          end
        end

        context 'when the canonical staff has other matches in another game' do
          before do
            create(:staff, canonical_staff:)
          end

          it 'is valid' do
            expect(staff).to be_valid
          end
        end

        context 'when the canonical staff has other matches in the same game' do
          before do
            create(:staff, canonical_staff:, game:)
          end

          it 'is invalid' do
            validate
            expect(staff.errors[:base]).to include('is a duplicate of a unique in-game item')
          end
        end
      end
    end

    describe '#canonical_models' do
      context 'when there is a canonical_staff associated' do
        let(:staff) { create(:staff, :with_matching_canonical) }

        it 'is valid' do
          expect(staff).to be_valid
        end
      end

      context 'when there is no canonical_staff associated' do
        let(:game) { create(:game) }
        let(:staff) { build(:staff, game:, name: 'my staff') }

        context 'when there are multiple matching canonical staves' do
          before do
            create_list(
              :canonical_staff,
              2,
              name: staff.name,
            )
          end

          it 'is valid' do
            expect(staff).to be_valid
          end
        end

        context 'when the matching canonical staff is unique and has an existing association' do
          before do
            canonical_staff = create(
              :canonical_staff,
              name: 'My Staff',
              max_quantity: 1,
              unique_item: true,
              rare_item: true,
            )

            create(:staff, name: 'My Staff', game:, canonical_staff:)
          end

          it 'is invalid' do
            staff.validate
            expect(staff.errors[:base]).to include('is a duplicate of a unique in-game item')
          end
        end

        context 'when there are no matching canonical staves' do
          it 'is invalid' do
            validate
            expect(staff.errors[:base]).to include("doesn't match any item that exists in Skyrim")
          end
        end
      end
    end
  end

  describe '#canonical_model' do
    subject(:canonical_model) { staff.canonical_model }

    context 'when a canonical staff is associated' do
      let(:staff) { build(:staff, :with_matching_canonical) }

      it 'returns the canonical staff' do
        expect(canonical_model).to eq(staff.canonical_staff)
      end
    end

    context 'when no canonical staff is associated' do
      let(:staff) { build(:staff) }

      it 'returns nil' do
        expect(canonical_model).to be_nil
      end
    end
  end

  describe 'matching canonical models' do
    subject(:canonical_models) { staff.canonical_models }

    context 'when there are no matching canonical models' do
      let(:staff) { build(:staff) }

      it 'returns an empty ActiveRecord relation', :aggregate_failures do
        expect(canonical_models).to be_empty
        expect(canonical_models).to be_an(ActiveRecord::Relation)
      end
    end

    context 'when there are multiple matching canonical models' do
      let(:staff) { build(:staff, magical_effects: 'This staff has magical effects') }

      let!(:matching_canonicals) do
        create_list(
          :canonical_staff,
          2,
          name: staff.name,
          magical_effects: 'This staff has magical effects',
        )
      end

      before do
        create(:canonical_staff, name: staff.name)
      end

      it 'returns all the matching canonical models in an ActiveRecord relation', :aggregate_failures do
        expect(canonical_models).to be_an(ActiveRecord::Relation)
        expect(canonical_models).to contain_exactly(*matching_canonicals)
      end
    end

    context 'when updating attributes changes the canonical matches' do
      let(:staff) { create(:staff, :with_matching_canonical) }
      let!(:new_canonical) { create(:canonical_staff, name: 'Super Staff of Smiting') }

      it 'changes the canonical staff' do
        staff.name = 'super staff of smiting'

        expect(canonical_models).to contain_exactly(new_canonical)
      end
    end
  end

  describe 'setting a canonical model' do
    subject(:validate) { staff.validate }

    context 'when there is an existing canonical staff' do
      let(:staff) { create(:staff, :with_matching_canonical) }

      it "doesn't change anything" do
        expect { validate }
          .not_to change(staff.reload, :canonical_staff)
      end
    end

    context 'when there is a single matching canonical staff' do
      let(:game) { create(:game) }
      let(:staff) { build(:staff, name: 'my staff', unit_weight: nil, game:) }

      let!(:canonical_staff) do
        create(
          :canonical_staff,
          name: 'My Staff',
          unit_weight: 8,
          magical_effects: 'Does stuff',
        )
      end

      before do
        create(:staff, name: 'My Staff', canonical_staff:, game:)
      end

      it 'associates the canonical staff' do
        validate
        expect(staff.canonical_staff).to eq(canonical_staff)
      end

      it 'sets values from the canonical model', :aggregate_failures do
        validate
        expect(staff.name).to eq('My Staff')
        expect(staff.unit_weight).to eq(8)
        expect(staff.magical_effects).to eq('Does stuff')
      end
    end

    context 'when there are multiple matching canonicals' do
      let(:staff) { build(:staff, unit_weight: nil, magical_effects: nil) }

      before do
        create(:canonical_staff, name: staff.name, unit_weight: 8, magical_effects: 'foo')
        create(:canonical_staff, name: staff.name, unit_weight: 2)
      end

      it "doesn't associate a canonical model" do
        staff.validate
        expect(staff.canonical_staff).to be_nil
      end
    end

    context 'when updating the in-game item' do
      let(:staff) { create(:staff, :with_matching_canonical) }

      context 'when updating the in-game item changes the matching canonical' do
        let!(:new_canonical) { create(:canonical_staff, name: 'Awesome Staff of Hipness') }

        it 'changes the canonical model' do
          staff.name = 'Awesome Staff of Hipness'

          expect { validate }
            .to change(staff, :canonical_staff)
                  .to(new_canonical)
        end
      end

      context 'when updating the in-game item results in an ambiguous match' do
        before do
          create_list(
            :canonical_staff,
            2,
            name: 'Awesome Staff of Hipness',
          )
        end

        it 'removes the associated canonical model' do
          staff.name = 'Awesome Staff of Hipness'

          expect { validate }
            .to change(staff, :canonical_staff)
                  .to(nil)
        end
      end

      context 'when updating the in-game item results in no matches' do
        it 'removes the associated canonical model' do
          staff.name = 'awesome staff of hipness'

          expect { validate }
            .to change(staff, :canonical_staff)
                  .to(nil)
        end
      end
    end
  end

  describe '#spells' do
    subject(:spells) { staff.spells }

    let(:canonical_staff) { create(:canonical_staff) }

    context 'when there is an associated canonical model with spells' do
      let(:staff) { create(:staff, name: canonical_staff.name, canonical_staff:) }
      let(:spell) { create(:spell) }

      before do
        create(:spell) # this shouldn't be included
        create(:canonical_staves_spell, staff: canonical_staff, spell:)
      end

      it 'returns the spells of the associated canonical model' do
        expect(spells).to contain_exactly(spell)
      end

      it 'returns an ActiveRecord::Relation' do
        expect(spells).to be_an(ActiveRecord::Relation)
      end
    end

    context 'when there is an associated canonical model without spells' do
      let(:staff) { create(:staff, name: canonical_staff.name, canonical_staff:) }

      before do
        create(:spell) # this should not be included
      end

      it 'returns an empty ActiveRecord relation', :aggregate_failures do
        expect(spells).to be_an(ActiveRecord::Relation)
        expect(spells).to be_empty
      end
    end

    context 'when there is no associated canonical model' do
      let(:staff) { create(:staff, name: 'My Staff') }

      before do
        create_list(
          :canonical_staff,
          2,
          name: 'My Staff',
        )
      end

      it 'returns an empty ActiveRecord::Relation', :aggregate_failures do
        expect(spells).to be_an(ActiveRecord::Relation)
        expect(spells).to be_empty
      end
    end
  end

  describe '#powers' do
    subject(:powers) { staff.powers }

    let(:canonical_staff) { create(:canonical_staff) }

    context 'when there is an associated canonical model with powers' do
      let(:staff) { create(:staff, name: canonical_staff.name, canonical_staff:) }
      let(:power) { create(:power) }

      before do
        create(:power) # this shouldn't be included
        create(:canonical_powerables_power, powerable: canonical_staff, power:)
      end

      it 'returns the powers of the associated canonical model' do
        expect(powers).to contain_exactly(power)
      end

      it 'returns an ActiveRecord::Relation' do
        expect(powers).to be_an(ActiveRecord::Relation)
      end
    end

    context 'when there is an associated canonical model without powers' do
      let(:staff) { create(:staff, name: canonical_staff.name, canonical_staff:) }

      before do
        create(:power) # this should not be included
      end

      it 'returns an empty ActiveRecord relation', :aggregate_failures do
        expect(powers).to be_an(ActiveRecord::Relation)
        expect(powers).to be_empty
      end
    end

    context 'when there is no associated canonical model' do
      let(:staff) { create(:staff, name: 'My Staff') }

      before do
        create_list(
          :canonical_staff,
          2,
          name: 'My Staff',
        )
      end

      it 'returns an empty ActiveRecord::Relation', :aggregate_failures do
        expect(powers).to be_an(ActiveRecord::Relation)
        expect(powers).to be_empty
      end
    end
  end
end

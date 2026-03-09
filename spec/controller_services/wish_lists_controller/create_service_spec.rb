# frozen_string_literal: true

require 'rails_helper'
require 'service/created_result'
require 'service/not_found_result'
require 'service/unprocessable_entity_result'
require 'service/internal_server_error_result'

RSpec.describe WishListsController::CreateService do
  describe '#perform' do
    subject(:perform) { described_class.new(user, game.id, params).perform }

    let(:user) { create(:user) }

    context 'when the game is not found' do
      let(:game) { double(id: 898_243) }
      let(:params) { { title: 'My Wish List' } }

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the game belongs to another user' do
      let(:game) { create(:game) }
      let(:params) { { title: 'My Wish List' } }

      it "doesn't create a wish list" do
        expect { perform }
          .not_to change(WishList, :count)
      end

      it 'returns a Service::NotFoundResult' do
        expect(perform).to be_a(Service::NotFoundResult)
      end

      it "doesn't return any data", :aggregate_failures do
        expect(perform.resource).to be_blank
        expect(perform.errors).to be_blank
      end
    end

    context 'when the request tries to create an aggregate list' do
      let(:game) { create(:game, user:) }
      let(:params) { { title: 'All Items', aggregate: true } }

      it 'returns a Service::UnprocessableEntityResult' do
        expect(perform).to be_a(Service::UnprocessableEntityResult)
      end

      it 'sets an error' do
        expect(perform.errors).to eq(['Cannot manually create an aggregate wish list'])
      end
    end

    context 'when params are valid' do
      let!(:game) { create(:game, user:) }
      let(:params) { { title: 'Proudspire Manor' } }

      context 'when the game has other wish lists' do
        before { create(:wish_list, game:) }

        it 'creates a wish list for the given game' do
          expect { perform }
            .to change(game.wish_lists, :count).from(2).to(3)
        end

        it 'returns a Service::CreatedResult' do
          expect(perform).to be_a(Service::CreatedResult)
        end

        it 'sets the resource to the created list' do
          expect(perform.resource).to eq [game.wish_lists.find_by(title: 'Proudspire Manor')]
        end

        it 'updates the game' do
          t = Time.zone.now + 3.days
          Timecop.freeze(t) do
            perform
            expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
          end
        end
      end

      context "when the game doesn't have an aggregate wish list" do
        it 'creates two lists' do
          expect { perform }
            .to change(game.wish_lists, :count).from(0).to(2)
        end

        it 'creates an aggregate wish list for the given game' do
          perform
          expect(game.aggregate_wish_list).to be_present
        end

        it 'creates a regular wish list for the given game' do
          perform
          expect(game.wish_lists.last.title).to eq 'Proudspire Manor'
        end

        it 'updates the game' do
          t = Time.zone.now + 3.days
          Timecop.freeze(t) do
            perform
            expect(game.reload.updated_at).to be_within(0.005.seconds).of(t)
          end
        end

        it 'returns a Service::CreatedResult' do
          expect(perform).to be_a(Service::CreatedResult)
        end

        it 'sets the resource to include both lists' do
          expect(perform.resource).to eq(game.wish_lists.index_order)
        end
      end
    end

    context 'when params are invalid' do
      let(:game) { create(:game, user:) }
      let(:game_id) { game.id }
      let(:params) { { title: '|nvalid Tit|e' } }

      it 'does not create a wish list' do
        expect { perform }
          .not_to change(game.wish_lists, :count)
      end

      it 'returns a Service::UnprocessableEntityResult' do
        expect(perform).to be_a(Service::UnprocessableEntityResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq(["Title can only contain alphanumeric characters, spaces, commas (,), hyphens (-), and apostrophes (')"])
      end
    end

    context 'when something unexpected goes wrong' do
      let(:game) { create(:game, user:) }
      let(:params) { { title: 'Foobar' } }

      before { allow_any_instance_of(WishList).to receive(:save).and_raise(StandardError, 'Something went horribly wrong') }

      it 'returns a Service::InternalServerErrorResult' do
        expect(perform).to be_a(Service::InternalServerErrorResult)
      end

      it 'sets the errors' do
        expect(perform.errors).to eq ['Something went horribly wrong']
      end
    end
  end
end

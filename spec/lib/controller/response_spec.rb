# frozen_string_literal: true

require 'rails_helper'
require 'service/ok_result'
require 'service/no_content_result'
require 'service/method_not_allowed_result'
require 'service/unprocessable_entity_result'
require 'controller/response'

RSpec.describe Controller::Response do
  describe '#execute' do
    subject(:execute) { described_class.new(controller, result, options).execute }

    context 'when the result has no resource and the errors are empty' do
      let(:controller) { instance_double(WishListsController, head: nil) }
      let(:options) { {} }
      let(:result) { Service::NoContentResult.new(resource: nil, errors: []) }

      it 'returns the status with no response body' do
        execute
        expect(controller).to have_received(:head).with(:no_content)
      end
    end

    context 'when the resource is present but empty' do
      let(:controller) { instance_double(WishListsController, render: nil) }
      let(:options) { {} }
      let(:result) { Service::OkResult.new(resource: []) }

      it 'returns the empty resource' do
        execute
        expect(controller).to have_received(:render).with(json: [], status: :ok)
      end
    end

    context 'when there is a resource' do
      let(:controller) { instance_double(WishListsController, render: nil) }
      let(:options) { {} }
      let(:result) { Service::OkResult.new(resource:) }

      let(:resource) { { id: 927, user_id: 72, title: 'My List 2', created_at: Time.zone.now - 2.days, updated_at: Time.zone.now } }

      it 'renders the resource with the result status' do
        execute
        expect(controller).to have_received(:render).with(json: resource, status: :ok)
      end
    end

    context 'when there are errors' do
      let(:controller) { instance_double(WishListsController, render: nil) }
      let(:errors) { ['Cannot manually update an aggregate wish list'] }
      let(:options) { {} }
      let(:result) { Service::MethodNotAllowedResult.new(errors:) }

      it 'renders the errors with the result status' do
        execute
        expect(controller).to have_received(:render).with(json: { errors: }, status: :method_not_allowed)
      end
    end

    describe 'unexpected cases' do
      context 'when there is a resource and errors' do
        let(:controller) { instance_double(WishListsController, render: nil) }
        let(:options) { {} }
        let(:errors) { ['Title is already taken', 'Cannot manually create or update an aggregate wish list'] }
        let(:result) { Service::UnprocessableEntityResult.new(errors:, resource: { foo: 'bar' }) }

        it 'renders the errors' do
          execute
          expect(controller).to have_received(:render).with(json: { errors: }, status: :unprocessable_entity)
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'service/result'

RSpec.describe Service::Result do
  subject(:result) { described_class.new(options) }

  describe 'initialisation' do
    let(:options) { { status: :unprocessable_entity, errors: ['Title is already taken'] } }

    describe 'status' do
      it 'raises a NotImplementedError on the base class' do
        expect { result.status }
          .to raise_error NotImplementedError
      end
    end

    context 'when a resource is given' do
      let(:options) { { resource: { id: 32, uid: 'foobar', email: 'jane.doe@gmail.com', display_name: 'Jane Doe', photo_url: nil } } }

      it 'sets the resource if one is given' do
        expect(result.resource).to eq({ id: 32, uid: 'foobar', email: 'jane.doe@gmail.com', display_name: 'Jane Doe', photo_url: nil })
      end
    end

    context 'when no resource is given' do
      let(:options) { {} }

      it 'sets the resource to nil' do
        expect(result.resource).to be nil
      end
    end

    context 'when there are errors' do
      let(:options) { { errors: ['foo', ['bar', %w[baz qux]]] } }

      it 'sets the errors array to a flattened value' do
        expect(result.errors).to eq %w[foo bar baz qux]
      end
    end

    context 'when there is one error' do
      let(:options) { { error: 'foobar' } }

      it 'sets the errors to an array' do
        expect(result.errors).to eq %w[foobar]
      end
    end

    context 'when there are no errors' do
      let(:options) { {} }

      it 'sets the errors to an empty array' do
        expect(result.errors).to eq []
      end
    end
  end
end

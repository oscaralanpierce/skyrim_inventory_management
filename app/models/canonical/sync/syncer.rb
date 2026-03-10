# frozen_string_literal: true

module Canonical
  module Sync
    class Syncer
      def self.perform(preserve_existing_records:)
        new(preserve_existing_records:).perform
      end

      def initialize(preserve_existing_records:)
        @preserve_existing_records = preserve_existing_records
      end

      def perform
        Rails.logger.info("Syncing #{model_name.downcase.pluralize}...")

        ActiveRecord::Base.transaction do
          destroy_existing_models unless preserve_existing_records

          json_data.each {|object| create_or_update_model(object[:attributes]) }
        rescue StandardError => e
          Rails.logger.error("Unexpected error #{e.class} while syncing #{model_name.downcase.pluralize}: #{e.message}")
          raise e
        end
      end

      private

      attr_reader :preserve_existing_records

      def model_class
        raise NotImplementedError.new('Child class of Canonical::Sync::Syncer must define a model class')
      end

      def model_name
        model_class.to_s.scan(/[A-Z][a-z]*/).join(' ')
      end

      def model_identifier
        model_class.unique_identifier
      end

      def json_file_path
        raise NotImplementedError.new('Child class of Canonical::Sync::Syncer must define a #json_file_path method.')
      end

      def json_data
        @json_data ||= JSON.parse(File.read(json_file_path), symbolize_names: true)
      end

      def create_or_update_model(attributes)
        model = model_class.find_or_initialize_by(model_identifier => attributes[model_identifier])
        model.assign_attributes(attributes.except(model_identifier))
        model.save!
        model
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error("Error saving #{model_name.downcase} \"#{attributes[model_identifier]}\": #{e.message}")
        raise e
      rescue StandardError => e
        Rails.logger.error("Unexpected error #{e.class} saving #{model_name.downcase} \"#{attributes[model_identifier]}\": #{e.message}")
        raise e
      end

      def destroy_existing_models
        identifiers = json_data.map {|obj| obj.dig(:attributes, model_identifier) }
        model_class.where.not(model_identifier => identifiers).destroy_all
      end
    end
  end
end

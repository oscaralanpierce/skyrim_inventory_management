# frozen_string_literal: true

module Canonical
  module Sync
    class AssociationSyncer < Syncer
      def perform
        raise PrerequisiteNotMetError.new(prerequisite_error_message) unless prerequisite_conditions_met?

        Rails.logger.info "Syncing #{model_name.downcase.pluralize}..."
        Rails.logger.warn "preserve_existing_records mode does not preserve associations for #{model_name.downcase.pluralize}" if preserve_existing_records && !preserve_associations?

        ActiveRecord::Base.transaction do
          destroy_existing_models unless preserve_existing_records

          json_data.each do |object|
            model = create_or_update_model(object.delete(:attributes))

            associations = object.keys

            next unless associations.any?

            associations.each do |association|
              reflection = model_class.reflect_on_association(association)
              association_name = reflection.through_reflection.name
              associated_model = reflection.source_reflection.name
              associated_model_class = reflection.klass
              associated_model_identifier = associated_model_class.unique_identifier
              associated_fk = reflection.foreign_key.to_sym

              if !preserve_existing_records || !preserve_associations?
                identifiers = object[association].pluck(associated_model_identifier)
                assn_ids = associated_model_class.where(associated_model_identifier => identifiers).ids
                model.send(association_name).where.not(associated_fk => assn_ids).destroy_all
              end

              object[association].each do |assn|
                join_model = model
                               .send(association_name)
                               .find_or_initialize_by(associated_model => associated_model_class.find_by(associated_model_identifier => assn.delete(associated_model_identifier)))
                join_model.assign_attributes(assn)
                join_model.save!
              rescue ActiveRecord::RecordInvalid => e
                Rails.logger.error "Validation error saving associations for #{model_name.downcase} \"#{model.send(model_identifier)}\": #{e.message}"
                raise e
              end
            end
          end
        rescue StandardError => e
          Rails.logger.error "Unexpected error #{e.class} while syncing #{model_name.downcase.pluralize}: #{e.message}"
          raise e
        end
      rescue PrerequisiteNotMetError => e
        Rails.logger.error e.message
        raise e
      end

      private

      def prerequisites
        []
      end

      def prerequisite_error_message
        "Prerequisite(s) not met: sync #{prerequisites.map(&:to_s).join(', ')} before #{model_name.downcase.pluralize}"
      end

      def prerequisite_conditions_met?
        prerequisites.empty? || prerequisites.all?(&:any?)
      end

      def preserve_associations?
        true
      end
    end
  end
end

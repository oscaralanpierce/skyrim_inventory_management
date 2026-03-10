# frozen_string_literal: true

module Canonical
  module Sync
    class Ingredients < AssociationSyncer
      def self.perform(preserve_existing_records:)
        Rails.logger.warn('Ingredient syncer cannot preserve existing records') if preserve_existing_records
        super
      end

      private

      def model_class
        Canonical::Ingredient
      end

      def json_file_path
        Rails.root.join('lib', 'tasks', 'canonical_models', 'canonical_ingredients.json')
      end

      def preserve_associations?
        false
      end

      def prerequisites
        [AlchemicalProperty]
      end
    end
  end
end

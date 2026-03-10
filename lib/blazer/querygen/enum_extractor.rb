# frozen_string_literal: true

module Blazer
  module Querygen
    # Extracts enum definitions from ActiveRecord models and enumerize attributes
    # Returns metadata only (value mappings), never actual data
    class EnumExtractor
      # Returns enum mappings grouped by table and column
      # @return [Hash] { "table_name" => { "column_name" => { "label" => value, ... } } }
      def extract
        return {} unless Blazer::Querygen.config.include_enum_values

        models = load_models
        build_enum_mapping(models)
      rescue StandardError => e
        log_debug("Failed to extract enum metadata: #{e.message}")
        {}
      end

      private

      def load_models
        eager_load_models if should_eager_load?

        return [] unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.descendants.select { |m| model_has_table?(m) }
      rescue StandardError => e
        log_debug("Failed to load models: #{e.message}")
        []
      end

      def should_eager_load?
        defined?(Rails) &&
          Rails.respond_to?(:application) &&
          Rails.application &&
          !Rails.application.config.eager_load
      end

      def eager_load_models
        # Only eager-load model directories, not the entire application
        if Rails.autoloaders.respond_to?(:main)
          model_paths = Rails.application.paths["app/models"].to_a
          model_paths.each { |path| Rails.autoloaders.main.eager_load_dir(path) }
        else
          Rails.application.eager_load!
        end
      rescue StandardError => e
        log_debug("Failed to eager load models: #{e.message}")
      end

      def model_has_table?(model)
        return false if model.abstract_class?

        model.table_name.present?
      rescue StandardError
        false
      end

      def build_enum_mapping(models)
        models.each_with_object({}) do |model, mapping|
          table = safe_table_name(model)
          next unless table

          enums = extract_activerecord_enums(model).merge(extract_enumerize_enums(model))
          next unless enums.any?

          mapping[table] = (mapping[table] || {}).merge(enums)
        end
      end

      def safe_table_name(model)
        model.table_name
      rescue StandardError
        nil
      end

      def extract_activerecord_enums(model)
        return {} unless model.respond_to?(:defined_enums)

        model.defined_enums.transform_values(&:dup)
      rescue StandardError
        {}
      end

      def extract_enumerize_enums(model)
        return {} unless model.respond_to?(:enumerized_attributes)

        model.enumerized_attributes.each_with_object({}) do |attr, result|
          values = attr.values.map(&:to_s)
          result[attr.name.to_s] = values.each_with_object({}) { |v, h| h[v] = v }
        end
      rescue StandardError
        {}
      end

      def log_debug(message)
        return unless defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger

        Rails.logger.debug("[Blazer::Querygen] #{message}")
      end
    end
  end
end

# frozen_string_literal: true

module Blazer
  module Querygen
    # Configuration class for Blazer::Querygen
    class Configuration
      # OpenAI settings
      attr_accessor :ai_model
      attr_accessor :api_key, :allowed_operations, :max_retries, :max_tables_in_context, :include_column_comments,
                    :excluded_tables

      # Security settings
      attr_accessor :sanitize_queries

      # Performance settings
      attr_accessor :timeout

      # Schema extraction settings
      attr_accessor :include_table_comments

      def initialize
        @ai_model = "gpt-5.2"
        @api_key = ENV.fetch("OPENAI_API_KEY", nil)

        @sanitize_queries = true
        @allowed_operations = [:select]

        @timeout = 10
        @max_retries = 3
        @max_tables_in_context = 50

        @include_table_comments = true
        @include_column_comments = true
        @excluded_tables = %w[schema_migrations ar_internal_metadata]
      end
    end
  end
end

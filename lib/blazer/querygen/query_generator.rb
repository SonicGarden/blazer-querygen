# frozen_string_literal: true

module Blazer
  module Querygen
    # Service class for generating SQL queries from natural language prompts
    # Orchestrates schema extraction, AI generation, and SQL sanitization
    class QueryGenerator
      class UnsafeQueryError < StandardError; end

      # Generate SQL query from natural language prompt
      #
      # @param prompt [String] Natural language description of desired query
      # @param data_source [String, nil] Optional data source name (for future multi-datasource support)
      # @return [Hash] Result hash with keys:
      #   - :sql [String] Generated SQL query (sanitized if config.sanitize_queries is true)
      #   - :prompt [String] Original prompt
      #   - :model [String] AI model used
      #   - :success [Boolean] Always true on success (exceptions raised on failure)
      # @raise [UnsafeQueryError] If SQL contains dangerous operations (when sanitize_queries is true)
      # @raise [AIClient::APIError] If OpenAI API request fails
      # @raise [AIClient::TimeoutError] If OpenAI API request times out
      # @raise [AIClient::ConfigurationError] If OpenAI API key is missing
      def generate(prompt:, data_source: nil)
        # Extract schema
        schema_extractor = SchemaExtractor.new
        schema = schema_extractor.extract(data_source)

        # Generate SQL via AI
        ai_client = AIClient.new
        response = ai_client.generate_query(prompt: prompt, schema: schema)

        # Sanitize SQL if configured
        sanitized_sql = sanitize(response[:sql])

        {
          sql: sanitized_sql,
          prompt: prompt,
          model: response[:model],
          success: true
        }
      end

      private

      # Sanitize SQL to prevent dangerous operations
      # @param sql [String] SQL query to sanitize
      # @return [String] Original SQL if safe
      # @raise [UnsafeQueryError] If SQL contains dangerous operations
      def sanitize(sql)
        return sql unless Blazer::Querygen.config.sanitize_queries

        # Check for dangerous operations
        dangerous_patterns = /\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE|GRANT|REVOKE)\b/i
        if sql.match?(dangerous_patterns)
          raise UnsafeQueryError, "Unsafe SQL operation detected. Only SELECT queries are allowed."
        end

        sql
      end
    end
  end
end

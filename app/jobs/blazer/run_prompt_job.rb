# frozen_string_literal: true

module Blazer
  # Background job for asynchronous query generation
  class RunPromptJob < ApplicationJob
    queue_as :default

    retry_on Blazer::Querygen::AIClient::TimeoutError, wait: 5.seconds, attempts: 3
    discard_on Blazer::Querygen::AIClient::APIError

    def perform(prompt:, data_source: nil)
      schema_extractor = Blazer::Querygen::SchemaExtractor.new
      schema = schema_extractor.extract(data_source)

      client = Blazer::Querygen::AIClient.new
      response = client.generate_query(prompt: prompt, schema: schema)

      sanitized_sql = sanitize_sql(response[:sql])

      {
        success: true,
        sql: sanitized_sql,
        prompt: prompt,
        model: response[:model]
      }
    rescue StandardError => e
      Rails.logger.error("Blazer::Querygen - Query generation failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      raise
    end

    private

    def sanitize_sql(sql)
      return sql unless Blazer::Querygen.config.sanitize_queries

      # Check for dangerous operations
      dangerous_patterns = /\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE|GRANT|REVOKE)\b/i
      if sql.match?(dangerous_patterns)
        raise Blazer::Querygen::Error, "Unsafe SQL operation detected. Only SELECT queries are allowed."
      end

      sql
    end
  end
end

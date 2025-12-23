# frozen_string_literal: true

module Blazer
  # Controller for AI-powered query generation
  class PromptsController < BaseController
    def run
      prompt = params[:prompt]
      data_source = params[:data_source]

      if prompt.blank?
        render json: { error: "Prompt is required", success: false }, status: :unprocessable_entity
        return
      end

      if async_generation?
        # Async generation via background job
        job = RunPromptJob.perform_later(
          prompt: prompt,
          data_source: data_source
        )

        render json: {
          job_id: job.job_id,
          status: "processing",
          success: true
        }
      else
        # Synchronous generation for development
        result = generate_query_sync(prompt, data_source)
        render json: result
      end
    rescue Blazer::Querygen::AIClient::ConfigurationError => e
      render json: { error: "Configuration error: #{e.message}", success: false }, status: :service_unavailable
    rescue StandardError => e
      Rails.logger.error("Query generation failed: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
      render json: { error: "Query generation failed: #{e.message}", success: false }, status: :internal_server_error
    end

    def health
      if Blazer::Querygen.config.api_key.present?
        render json: {
          status: "configured",
          model: Blazer::Querygen.config.ai_model,
          success: true
        }
      else
        render json: {
          status: "not_configured",
          error: "OpenAI API key is not configured",
          success: false
        }, status: :service_unavailable
      end
    end

    private

    def async_generation?
      Rails.env.production? || params[:async] == "true"
    end

    def generate_query_sync(prompt, data_source)
      schema_extractor = Blazer::Querygen::SchemaExtractor.new
      schema = schema_extractor.extract(data_source)

      client = Blazer::Querygen::AIClient.new
      response = client.generate_query(prompt: prompt, schema: schema)

      sanitized_sql = sanitize_sql(response[:sql])

      {
        sql: sanitized_sql,
        prompt: prompt,
        model: response[:model],
        success: true
      }
    rescue Blazer::Querygen::AIClient::APIError => e
      { error: e.message, success: false }
    rescue Blazer::Querygen::AIClient::TimeoutError => e
      { error: "Request timed out: #{e.message}", success: false }
    end

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

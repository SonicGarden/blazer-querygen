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

      query_generator = Blazer::Querygen::QueryGenerator.new
      result = query_generator.generate(prompt: prompt, data_source: data_source)
      render json: result
    rescue Blazer::Querygen::QueryGenerator::UnsafeQueryError => e
      render json: { error: e.message, success: false }, status: :unprocessable_entity
    rescue Blazer::Querygen::AIClient::ConfigurationError => e
      render json: { error: "Configuration error: #{e.message}", success: false }, status: :service_unavailable
    rescue Blazer::Querygen::AIClient::APIError => e
      render json: { error: e.message, success: false }, status: :internal_server_error
    rescue Blazer::Querygen::AIClient::TimeoutError => e
      render json: { error: "Request timed out: #{e.message}", success: false }, status: :request_timeout
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
  end
end

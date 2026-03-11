# frozen_string_literal: true

module Blazer
  # Controller for AI-powered query generation
  class PromptsController < BaseController
    MAX_PROMPT_LENGTH = 2000
    MAX_SQL_LENGTH = 10_000

    def run # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/MethodLength
      prompt = params[:prompt]
      data_source = params[:data_source]
      current_sql = params[:current_sql]

      if prompt.blank?
        render json: { error: "Prompt is required", success: false }, status: :unprocessable_entity
        return
      end

      if prompt.length > MAX_PROMPT_LENGTH
        render json: { error: "Prompt is too long (max #{MAX_PROMPT_LENGTH} characters)", success: false },
               status: :unprocessable_entity
        return
      end

      if current_sql.present? && current_sql.length > MAX_SQL_LENGTH
        render json: { error: "Current SQL is too long (max #{MAX_SQL_LENGTH} characters)", success: false },
               status: :unprocessable_entity
        return
      end

      query_generator = Blazer::Querygen::QueryGenerator.new
      result = query_generator.generate(prompt: prompt, data_source: data_source, current_sql: current_sql)
      render json: result
    rescue Blazer::Querygen::QueryGenerator::UnsafeQueryError => e
      render json: { error: e.message, success: false }, status: :unprocessable_entity
    rescue Blazer::Querygen::AIClient::ConfigurationError
      render json: { error: "AI service is not configured", success: false }, status: :service_unavailable
    rescue Blazer::Querygen::AIClient::TimeoutError
      render json: { error: "Request timed out. Please try again.", success: false }, status: :request_timeout
    rescue Blazer::Querygen::AIClient::APIError
      render json: { error: "AI service error. Please try again.", success: false }, status: :internal_server_error
    rescue StandardError => e
      Rails.logger.error("[Blazer::Querygen] Query generation failed: #{e.message}")
      Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
      render json: { error: "An unexpected error occurred", success: false }, status: :internal_server_error
    end

    def health
      if Blazer::Querygen.config.api_key.present?
        render json: { status: "configured", success: true }
      else
        render json: { status: "not_configured", success: false }, status: :service_unavailable
      end
    end
  end
end

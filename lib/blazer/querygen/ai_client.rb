# frozen_string_literal: true

require "openai"

module Blazer
  module Querygen
    # OpenAI API client for query generation
    class AIClient
      class APIError < StandardError; end
      class TimeoutError < StandardError; end
      class ConfigurationError < StandardError; end

      def initialize(model: nil, api_key: nil)
        @model = model || Blazer::Querygen.config.ai_model
        @api_key = api_key || Blazer::Querygen.config.api_key

        raise ConfigurationError, "OpenAI API key is not configured" if @api_key.nil? || @api_key.empty?

        @client = OpenAI::Client.new(access_token: @api_key)
      end

      def generate_query(prompt:, schema:)
        with_retry do
          # Build prompts using PromptBuilder
          system_prompt_content = PromptBuilder.system_prompt
          user_prompt_content = PromptBuilder.build_user_prompt(prompt, schema)

          parameters = {
            model: @model,
            messages: [
              { role: "system", content: system_prompt_content },
              { role: "user", content: user_prompt_content }
            ],
            temperature: 0.2
          }

          # Use appropriate token parameter based on model
          if reasoning_model?
            # o1 series models use max_completion_tokens and don't support temperature/system role
            parameters.delete(:temperature)
            parameters[:max_completion_tokens] = 1000
            # o1 models don't support system messages, combine into user message
            parameters[:messages] = [
              { role: "user", content: "#{system_prompt_content}\n\n#{user_prompt_content}" }
            ]
          else
            # Standard models use max_tokens
            parameters[:max_tokens] = 1000
          end

          response = @client.chat(parameters: parameters)

          sql = extract_sql_from_response(response)
          {
            sql: sql,
            model: @model,
            raw_response: response
          }
        end
      end

      private

      def reasoning_model?
        # Reasoning models (o1 series, gpt-5.x) use different API parameters
        # These models use max_completion_tokens instead of max_tokens
        # and don't support temperature or system messages
        model_str = @model.to_s
        model_str.start_with?("o1") || model_str.start_with?("gpt-5")
      end

      def extract_sql_from_response(response)
        content = response.dig("choices", 0, "message", "content")
        raise APIError, "No content in API response" if content.nil? || content.empty?

        # Remove markdown code blocks if present
        content.gsub(/```sql\n?/, "").gsub(/```\n?/, "").strip
      end

      def with_retry(max_retries: Blazer::Querygen.config.max_retries, &block)
        attempts = 0
        begin
          attempts += 1
          Timeout.timeout(Blazer::Querygen.config.timeout, &block)
        rescue Timeout::Error, Net::OpenTimeout => e
          retry if attempts < max_retries
          raise TimeoutError, "API request timed out after #{max_retries} attempts: #{e.message}"
        rescue StandardError => e
          retry if attempts < max_retries && retryable_error?(e)
          raise APIError, "API request failed: #{e.message}"
        end
      end

      def retryable_error?(error)
        # Retry on rate limit or server errors
        error.is_a?(Faraday::Error) ||
          (error.respond_to?(:message) && error.message.match?(/rate limit|server error|timeout/i))
      end
    end
  end
end

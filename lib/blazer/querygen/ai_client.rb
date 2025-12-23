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
          parameters = {
            model: @model,
            messages: [
              { role: "system", content: system_prompt },
              { role: "user", content: build_user_prompt(prompt, schema) }
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
              { role: "user", content: "#{system_prompt}\n\n#{build_user_prompt(prompt, schema)}" }
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

      def system_prompt
        <<~PROMPT
          You are an expert SQL query generator. Your task is to generate valid SQL queries based on user requests.

          IMPORTANT RULES:
          1. Generate ONLY SELECT statements
          2. Do NOT generate INSERT, UPDATE, DELETE, DROP, CREATE, ALTER, or TRUNCATE statements
          3. Return ONLY the SQL query without any explanation or markdown formatting
          4. Use proper SQL syntax
          5. Include appropriate JOINs based on table relationships
          6. Add LIMIT clauses for safety when appropriate
          7. Use table and column names exactly as provided in the schema
        PROMPT
      end

      def build_user_prompt(prompt, schema)
        <<~PROMPT
          Generate a SQL query for the following request:
          #{prompt}

          Database Schema:
          #{format_schema(schema)}

          Return only the SQL query without any explanation or formatting.
        PROMPT
      end

      def format_schema(schema)
        schema.map do |table|
          columns_text = table[:columns].map do |col|
            comment_part = col[:comment] ? " -- #{col[:comment]}" : ""
            "  #{col[:name]} (#{col[:type]})#{comment_part}"
          end.join("\n")

          table_comment = table[:comment] ? "\n  Comment: #{table[:comment]}" : ""
          "Table: #{table[:name]}#{table_comment}\n#{columns_text}"
        end.join("\n\n")
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

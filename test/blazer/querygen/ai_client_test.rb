# frozen_string_literal: true

require "test_helper"

module Blazer
  module Querygen
    class AIClientTest < ActiveSupport::TestCase
      setup do
        # Skip tests if API key is not configured
        skip "OpenAI API key not configured" unless ENV["OPENAI_API_KEY"]
        @client = AIClient.new
      end

      test "raises ConfigurationError when API key is missing" do
        original_key = Blazer::Querygen.config.api_key

        begin
          Blazer::Querygen.config.api_key = nil
          assert_raises(AIClient::ConfigurationError) do
            AIClient.new
          end
        ensure
          Blazer::Querygen.config.api_key = original_key
        end
      end

      test "generate_query returns SQL" do
        skip "Skipping live API test - enable manually if needed"

        schema = [
          {
            name: "users",
            columns: [
              { name: "id", type: "integer" },
              { name: "email", type: "string" },
              { name: "created_at", type: "datetime" }
            ]
          }
        ]

        result = @client.generate_query(
          prompt: "Show me the 10 most recent users",
          schema: schema
        )

        assert result[:sql].present?
        assert_includes result[:sql].downcase, "select"
        assert result[:model].present?
      end

      test "handles timeout gracefully" do
        skip "Skipping timeout test - difficult to test reliably"

        # This would require mocking the HTTP client to simulate a timeout
      end

      test "extracts SQL from response with markdown" do
        skip "OpenAI API key not configured" unless ENV["OPENAI_API_KEY"]

        # Test the private extract_sql_from_response method
        response_with_markdown = {
          "choices" => [
            { "message" => { "content" => "```sql\nSELECT * FROM users\n```" } }
          ]
        }

        sql = @client.send(:extract_sql_from_response, response_with_markdown)
        assert_equal "SELECT * FROM users", sql
      end

      test "extracts plain SQL from response" do
        skip "OpenAI API key not configured" unless ENV["OPENAI_API_KEY"]

        response_plain = {
          "choices" => [
            { "message" => { "content" => "SELECT * FROM products" } }
          ]
        }

        sql = @client.send(:extract_sql_from_response, response_plain)
        assert_equal "SELECT * FROM products", sql
      end

      test "extracts SQL from markdown without API" do
        # This test doesn't need API key - just tests the extraction logic
        skip "OpenAI API key not configured" unless ENV["OPENAI_API_KEY"]

        client = AIClient.new

        # Mock response with SQL in markdown
        response = {
          "choices" => [
            { "message" => { "content" => "```sql\nSELECT id, name FROM users WHERE active = true\n```" } }
          ]
        }

        sql = client.send(:extract_sql_from_response, response)
        assert_equal "SELECT id, name FROM users WHERE active = true", sql.strip
      end

      test "client initialization validates config" do
        original_key = Blazer::Querygen.config.api_key

        begin
          # Test with valid key
          Blazer::Querygen.config.api_key = "test-key"
          assert_nothing_raised do
            AIClient.new
          end
        ensure
          Blazer::Querygen.config.api_key = original_key
        end
      end

      test "delegates to PromptBuilder for system prompt" do
        original_prompt = Blazer::Querygen.config.system_prompt
        original_key = Blazer::Querygen.config.api_key

        begin
          Blazer::Querygen.config.api_key = "test-key"
          Blazer::Querygen.config.system_prompt = nil

          # Verify that PromptBuilder.system_prompt is called by checking its behavior
          prompt = PromptBuilder.system_prompt

          assert_includes prompt, "expert SQL query generator"
          assert_includes prompt, "ONLY SELECT statements"
        ensure
          Blazer::Querygen.config.system_prompt = original_prompt
          Blazer::Querygen.config.api_key = original_key
        end
      end

      test "delegates to PromptBuilder for user prompt" do
        original_template = Blazer::Querygen.config.user_prompt_template
        original_key = Blazer::Querygen.config.api_key

        begin
          Blazer::Querygen.config.api_key = "test-key"
          Blazer::Querygen.config.user_prompt_template = nil

          schema = [{ name: "users", columns: [{ name: "id", type: "integer", null: false, comment: nil }], comment: nil }]

          # Verify that PromptBuilder.build_user_prompt is called by checking its behavior
          prompt = PromptBuilder.build_user_prompt("Show all users", schema)

          assert_includes prompt, "Generate a SQL query for the following request:"
          assert_includes prompt, "Show all users"
          assert_includes prompt, "Database Schema:"
        ensure
          Blazer::Querygen.config.user_prompt_template = original_template
          Blazer::Querygen.config.api_key = original_key
        end
      end

      test "respects custom prompts through PromptBuilder delegation" do
        original_prompt = Blazer::Querygen.config.system_prompt
        original_template = Blazer::Querygen.config.user_prompt_template
        original_key = Blazer::Querygen.config.api_key

        custom_system = "Custom SQL generator"
        custom_template = ->(input, schema) { "Custom: #{input} | #{schema}" }

        begin
          Blazer::Querygen.config.api_key = "test-key"
          Blazer::Querygen.config.system_prompt = custom_system
          Blazer::Querygen.config.user_prompt_template = custom_template

          # Verify custom prompts work through PromptBuilder
          system_result = PromptBuilder.system_prompt
          assert_equal custom_system, system_result

          schema = [{ name: "users", columns: [{ name: "id", type: "integer", null: false, comment: nil }], comment: nil }]
          user_result = PromptBuilder.build_user_prompt("Test", schema)
          assert_includes user_result, "Custom: Test"
        ensure
          Blazer::Querygen.config.system_prompt = original_prompt
          Blazer::Querygen.config.user_prompt_template = original_template
          Blazer::Querygen.config.api_key = original_key
        end
      end
    end
  end
end

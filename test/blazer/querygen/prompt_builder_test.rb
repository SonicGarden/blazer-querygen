# frozen_string_literal: true

require "test_helper"

module Blazer
  module Querygen
    class PromptBuilderTest < ActiveSupport::TestCase
      test "system_prompt returns default prompt when not configured" do
        original_prompt = Blazer::Querygen.config.system_prompt

        begin
          Blazer::Querygen.config.system_prompt = nil

          prompt = PromptBuilder.system_prompt

          assert_includes prompt, "expert SQL query generator"
          assert_includes prompt, "ONLY SELECT statements"
          assert_includes prompt, "IMPORTANT RULES:"
        ensure
          Blazer::Querygen.config.system_prompt = original_prompt
        end
      end

      test "system_prompt returns custom prompt when configured" do
        original_prompt = Blazer::Querygen.config.system_prompt
        custom_prompt = "Custom SQL generator instructions"

        begin
          Blazer::Querygen.config.system_prompt = custom_prompt

          prompt = PromptBuilder.system_prompt

          assert_equal custom_prompt, prompt
        ensure
          Blazer::Querygen.config.system_prompt = original_prompt
        end
      end

      test "build_user_prompt returns default format when not configured" do
        original_template = Blazer::Querygen.config.user_prompt_template

        begin
          Blazer::Querygen.config.user_prompt_template = nil

          schema = [
            {
              name: "users",
              columns: [
                { name: "id", type: "integer", null: false, comment: nil },
                { name: "email", type: "string", null: false, comment: "User email" }
              ],
              comment: "User accounts"
            }
          ]

          prompt = PromptBuilder.build_user_prompt("Show all users", schema)

          assert_includes prompt, "Generate a SQL query for the following request:"
          assert_includes prompt, "Show all users"
          assert_includes prompt, "Database Schema:"
          assert_includes prompt, "Table: users"
          assert_includes prompt, "id (integer)"
          assert_includes prompt, "email (string) -- User email"
        ensure
          Blazer::Querygen.config.user_prompt_template = original_template
        end
      end

      test "build_user_prompt uses custom template when configured" do
        original_template = Blazer::Querygen.config.user_prompt_template
        custom_template = lambda do |user_input, formatted_schema|
          "Custom: #{user_input} | Schema: #{formatted_schema}"
        end

        begin
          Blazer::Querygen.config.user_prompt_template = custom_template

          schema = [{ name: "users", columns: [{ name: "id", type: "integer", null: false, comment: nil }], comment: nil }]

          prompt = PromptBuilder.build_user_prompt("Show all users", schema)

          assert_includes prompt, "Custom: Show all users"
          assert_includes prompt, "Schema:"
          assert_includes prompt, "Table: users"
        ensure
          Blazer::Querygen.config.user_prompt_template = original_template
        end
      end

      test "format_schema handles empty schema" do
        result = PromptBuilder.format_schema([])
        assert_equal "No schema information available.", result
      end

      test "format_schema formats single table without comments" do
        schema = [
          {
            name: "users",
            columns: [
              { name: "id", type: "integer", null: false, comment: nil },
              { name: "email", type: "string", null: false, comment: nil }
            ],
            comment: nil
          }
        ]

        result = PromptBuilder.format_schema(schema)

        assert_includes result, "Table: users"
        assert_includes result, "id (integer)"
        assert_includes result, "email (string)"
        refute_includes result, "Comment:"
        refute_includes result, "--"
      end

      test "format_schema formats table with table comment" do
        schema = [
          {
            name: "users",
            columns: [{ name: "id", type: "integer", null: false, comment: nil }],
            comment: "User accounts"
          }
        ]

        result = PromptBuilder.format_schema(schema)

        assert_includes result, "Table: users"
        assert_includes result, "Comment: User accounts"
        assert_includes result, "id (integer)"
      end

      test "format_schema formats columns with comments" do
        schema = [
          {
            name: "users",
            columns: [
              { name: "id", type: "integer", null: false, comment: "Primary key" },
              { name: "email", type: "string", null: false, comment: "User email address" }
            ],
            comment: nil
          }
        ]

        result = PromptBuilder.format_schema(schema)

        assert_includes result, "id (integer) -- Primary key"
        assert_includes result, "email (string) -- User email address"
      end

      test "format_schema formats multiple tables" do
        schema = [
          {
            name: "users",
            columns: [{ name: "id", type: "integer", null: false, comment: nil }],
            comment: "User accounts"
          },
          {
            name: "products",
            columns: [{ name: "id", type: "integer", null: false, comment: nil }],
            comment: "Product catalog"
          }
        ]

        result = PromptBuilder.format_schema(schema)

        assert_includes result, "Table: users"
        assert_includes result, "Comment: User accounts"
        assert_includes result, "Table: products"
        assert_includes result, "Comment: Product catalog"

        # Verify tables are separated by blank line
        assert_includes result, "\n\n"
      end

      test "format_schema matches AIClient original format exactly" do
        # This test ensures backward compatibility
        schema = [
          {
            name: "orders",
            columns: [
              { name: "id", type: "bigint", null: false, comment: "Order ID" },
              { name: "user_id", type: "integer", null: false, comment: nil },
              { name: "total", type: "decimal", null: false, comment: "Order total" }
            ],
            comment: "Customer orders"
          }
        ]

        result = PromptBuilder.format_schema(schema)

        expected = <<~TEXT.chomp
          Table: orders
            Comment: Customer orders
            id (bigint) -- Order ID
            user_id (integer)
            total (decimal) -- Order total
        TEXT

        assert_equal expected, result
      end
    end
  end
end

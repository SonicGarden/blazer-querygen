# frozen_string_literal: true

require "test_helper"

module Blazer
  module Querygen
    class PromptBuilderTest < ActiveSupport::TestCase
      test "system_prompt contains SQL generation guidelines" do
        prompt = PromptBuilder.system_prompt

        assert_includes prompt, "SQL query generator"
        assert_includes prompt, "SELECT"
        assert_includes prompt, "no INSERT" # Ensures it warns against INSERT
      end

      test "build_user_prompt includes schema and query" do
        schema = [
          {
            name: "users",
            comment: "User accounts",
            columns: [
              { name: "id", type: "integer", comment: nil },
              { name: "email", type: "string", comment: "User email address" }
            ]
          }
        ]

        query = "Show me all users"
        prompt = PromptBuilder.build_user_prompt(query, schema)

        assert_includes prompt, "users"
        assert_includes prompt, "id"
        assert_includes prompt, "email"
        assert_includes prompt, "Show me all users"
        assert_includes prompt, "User accounts"
        assert_includes prompt, "User email address"
      end

      test "format_schema handles empty schema" do
        schema = []
        formatted = PromptBuilder.format_schema(schema)

        assert_equal "No schema information available.", formatted
      end

      test "format_schema formats tables with columns" do
        schema = [
          {
            name: "products",
            comment: "Product catalog",
            columns: [
              { name: "id", type: "integer", comment: nil },
              { name: "name", type: "string", comment: "Product name" }
            ]
          }
        ]

        formatted = PromptBuilder.format_schema(schema)

        assert_includes formatted, "Table: products"
        assert_includes formatted, "(Product catalog)"
        assert_includes formatted, "id: integer"
        assert_includes formatted, "name: string"
        assert_includes formatted, "(Product name)"
      end

      test "format_schema handles nil comments" do
        schema = [
          {
            name: "orders",
            comment: nil,
            columns: [
              { name: "id", type: "integer", comment: nil }
            ]
          }
        ]

        formatted = PromptBuilder.format_schema(schema)

        assert_includes formatted, "Table: orders"
        assert_includes formatted, "id: integer"
        assert_not_includes formatted, "(nil)"
      end
    end
  end
end

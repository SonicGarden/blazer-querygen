# frozen_string_literal: true

module Blazer
  module Querygen
    # Builds prompts for AI query generation
    class PromptBuilder
      def self.system_prompt
        <<~PROMPT
          You are a SQL query generator. Your task is to convert natural language descriptions into valid SQL queries.

          Guidelines:
          - Generate ONLY SELECT queries (no INSERT, UPDATE, DELETE, DROP, etc.)
          - Use proper SQL syntax and best practices
          - Include appropriate JOINs when multiple tables are referenced
          - Use clear and descriptive column aliases when needed
          - Add appropriate WHERE clauses for filtering
          - Use ORDER BY and LIMIT when relevant to the request
          - Return only the SQL query without any explanation or markdown formatting
          - Do not include ```sql or ``` code blocks, just the raw SQL

          Return ONLY the SQL query text.
        PROMPT
      end

      def self.build_user_prompt(natural_language_query, schema)
        schema_text = format_schema(schema)

        <<~PROMPT
          Database Schema:
          #{schema_text}

          User Request:
          #{natural_language_query}

          Generate a SQL SELECT query for this request.
        PROMPT
      end

      def self.format_schema(schema)
        return "No schema information available." if schema.empty?

        schema.map do |table|
          table_info = "Table: #{table[:name]}"
          table_info += " (#{table[:comment]})" if table[:comment].present?
          table_info += "\n"

          columns = table[:columns].map do |col|
            col_info = "  - #{col[:name]}: #{col[:type]}"
            col_info += " (#{col[:comment]})" if col[:comment].present?
            col_info
          end.join("\n")

          table_info + columns
        end.join("\n\n")
      end
    end
  end
end

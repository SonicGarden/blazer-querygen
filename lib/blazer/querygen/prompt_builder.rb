# frozen_string_literal: true

module Blazer
  module Querygen
    # Builds prompts for AI query generation
    # Handles both default and custom prompt configurations
    class PromptBuilder
      # Generate system prompt for AI
      # Uses custom prompt if configured, otherwise returns default
      #
      # @return [String] System prompt instructing AI on SQL generation rules
      def self.system_prompt
        # Use custom prompt if configured
        return Blazer::Querygen.config.system_prompt if Blazer::Querygen.config.system_prompt.present?

        # Default prompt (matches AIClient's original implementation)
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

      # Build user prompt combining natural language request with schema context
      # Uses custom template if configured, otherwise returns default
      #
      # @param natural_language_query [String] User's natural language request
      # @param schema [Array<Hash>] Database schema extracted by SchemaExtractor
      # @return [String] Complete user prompt with schema context
      def self.build_user_prompt(natural_language_query, schema)
        formatted_schema = format_schema(schema)

        # Use custom template if configured
        if Blazer::Querygen.config.user_prompt_template.present?
          return Blazer::Querygen.config.user_prompt_template.call(natural_language_query, formatted_schema)
        end

        # Default template (matches AIClient's original implementation)
        <<~PROMPT
          Generate a SQL query for the following request:
          #{natural_language_query}

          Database Schema:
          #{formatted_schema}

          Return only the SQL query without any explanation or formatting.
        PROMPT
      end

      # Format schema array into human-readable text
      # Matches AIClient's original format_schema implementation
      #
      # @param schema [Array<Hash>] Schema array with tables and columns
      # @return [String] Formatted schema text
      def self.format_schema(schema)
        return "No schema information available." if schema.empty?

        schema.map do |table|
          columns_text = table[:columns].map do |col|
            comment_part = col[:comment] ? " -- #{col[:comment]}" : ""
            "  #{col[:name]} (#{col[:type]})#{comment_part}"
          end.join("\n")

          table_comment = table[:comment] ? "\n  Comment: #{table[:comment]}" : ""
          "Table: #{table[:name]}#{table_comment}\n#{columns_text}"
        end.join("\n\n")
      end
    end
  end
end

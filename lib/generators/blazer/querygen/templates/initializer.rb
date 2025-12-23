# frozen_string_literal: true

# Blazer::Querygen Configuration
Blazer::Querygen.configure do |config|
  # OpenAI Model Configuration
  config.ai_model = "gpt-5.2"

  # OpenAI API Key
  # It's recommended to use environment variables for sensitive data
  config.api_key = ENV.fetch("OPENAI_API_KEY", nil)

  # Security Settings
  # Sanitize generated queries to prevent dangerous SQL operations
  config.sanitize_queries = true

  # Only allow SELECT operations (recommended for security)
  config.allowed_operations = [:select]

  # Performance Settings
  # API request timeout in seconds
  config.timeout = 10

  # Number of retries on timeout/transient errors
  config.max_retries = 3

  # Maximum number of tables to include in schema context
  config.max_tables_in_context = 50

  # Schema Extraction Settings
  # Include table comments in schema (if available)
  config.include_table_comments = true

  # Include column comments in schema (if available)
  config.include_column_comments = true

  # Tables to exclude from schema extraction
  config.excluded_tables = %w[schema_migrations ar_internal_metadata]
end

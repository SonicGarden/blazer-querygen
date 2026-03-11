# frozen_string_literal: true

Blazer::Querygen.configure do |config|
  config.ai_model = "gpt-4o-mini"
  config.api_key = ENV.fetch("OPENAI_API_KEY", nil)
  config.timeout = 30
  config.max_retries = 3
  config.max_tables_in_context = 50
  config.sanitize_queries = true
  config.excluded_tables = %w[schema_migrations ar_internal_metadata blazer_queries blazer_audits blazer_dashboards blazer_dashboard_queries blazer_checks]
  config.include_table_comments = true
  config.include_column_comments = true
  config.include_enum_values = true
end

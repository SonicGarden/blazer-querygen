## [Unreleased]

## [0.1.0] - 2026-01-04

### Added
- AI-powered SQL query generation from natural language prompts
- Integration with OpenAI API (supports gpt-5.x, gpt-4o, o1 models)
- Automatic database schema extraction (tables, columns, types, comments)
- Smart query generation leveraging table and column comments
- Configurable prompt customization (system prompt and user prompt templates)
- SQL sanitization to block dangerous operations (INSERT, UPDATE, DELETE, etc.)
- Security-first design: only schema metadata sent to AI, no actual data
- Rails Engine integration with automatic route injection
- JavaScript UI injection into Blazer's query editor
- Support for both Sprockets and Propshaft asset pipelines
- Comprehensive configuration options (11 configurable settings)
- Automatic retry logic with exponential backoff for API errors
- Generator for easy installation (`rails g blazer:querygen:install`)

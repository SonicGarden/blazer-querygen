# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Blazer::Querygen is a Rails Engine gem that adds AI-powered SQL query generation to [Blazer](https://github.com/ankane/blazer). It allows users to generate SQL queries from natural language prompts using OpenAI's API.

**Key Design Principle**: Security-first approach - only database schema metadata (table names, column names, types, comments) is sent to OpenAI. No actual data is ever transmitted.

## Development Commands

### Testing
```bash
# Run all tests
bundle exec rake test

# Run specific test file
bundle exec rake test TEST=test/blazer/querygen/ai_client_test.rb

# Run tests with specific OpenAI model (requires OPENAI_API_KEY)
OPENAI_API_KEY=your_key bundle exec rake test

# Default task (runs tests + rubocop)
bundle exec rake
```

### Linting
```bash
# Run rubocop
bundle exec rake rubocop

# Auto-fix issues
bundle exec rubocop -a
```

### Local Development with Another Rails App
```ruby
# In the consuming app's Gemfile
gem 'blazer-querygen', path: '/path/to/blazer-querygen'
```

## Architecture

### Rails Engine Pattern
This gem uses Rails Engine with `isolate_namespace` to:
- Mount routes dynamically into the host application (`/blazer/prompts/run`, `/blazer/querygen/health`)
- Register assets automatically (JavaScript for UI injection)
- Inject view paths for potential future partials

**Critical**: The Engine uses initializers to inject routes into the host app's route table automatically. No manual route mounting required.

### Core Components

#### 1. AIClient (`lib/blazer/querygen/ai_client.rb`)
Handles OpenAI API communication with model-aware parameter handling:

- **Reasoning Models** (o1-series, gpt-5.x): Use `max_completion_tokens`, no `temperature`, combine system+user messages
- **Standard Models** (gpt-4o, gpt-4-turbo, etc.): Use `max_tokens`, support `temperature` and separate system messages

The `reasoning_model?` method detects model type by checking if model name starts with "o1" or "gpt-5".

**Retry Logic**: Implements automatic retry with exponential backoff for rate limits and transient errors.

#### 2. SchemaExtractor (`lib/blazer/querygen/schema_extractor.rb`)
Extracts database schema without accessing actual data:

- Uses ActiveRecord's `connection.tables` and `connection.columns`
- Fetches PostgreSQL/MySQL table and column comments via raw SQL
- Respects `excluded_tables` configuration
- Limits tables sent to API via `max_tables_in_context`

**Current Limitation**: Always uses `ActiveRecord::Base.connection`. Multi-datasource support is a TODO (see comments in code).

#### 3. PromptBuilder (`lib/blazer/querygen/prompt_builder.rb`)
Constructs prompts for AI with schema context:

- `system_prompt`: Instructions for SQL generation (SELECT only, no markdown, etc.)
- `build_user_prompt`: Combines user request with formatted schema
- `format_schema`: Converts schema array to human-readable text with comments

#### 4. PromptsController (`app/controllers/blazer/prompts_controller.rb`)
Handles HTTP requests for query generation:

- Inherits from `Blazer::BaseController` (not `ApplicationController`) to use Blazer's authentication
- Supports both sync (development) and async (production) generation via `async_generation?`
- `sanitize_sql`: Regex-based blocker for dangerous SQL operations

**Security**: Uses regex `/\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE|GRANT|REVOKE)\b/i` to block unsafe operations.

#### 5. JavaScript UI (`app/assets/javascripts/blazer/querygen/prompts.js`)
Dynamically injects UI into Blazer's query editor:

- Finds `#statement-box.form-group` container
- Injects prompt textarea and generate button at top of container
- Uses Ace Editor API (`ace.edit()`) to set generated SQL
- Falls back to regular textarea if Ace Editor not found

**Critical**: Blazer uses Ace Editor, not a regular textarea. The selector `.ace_editor` and `ace.edit()` API are essential.

### Generator Pattern

The install generator (`lib/generators/blazer/querygen/install_generator.rb`):
1. Creates initializer with default configuration
2. Creates Blazer layout that includes querygen JavaScript
3. Attempts to add asset precompile configuration
4. Shows README with setup instructions

**ERB Template Escaping**: Layout template uses `<%%` syntax to escape ERB tags, so they're output as `<%` in the generated file (processed by the host app, not the generator).

## Configuration System

All configuration lives in `lib/blazer/querygen/configuration.rb` with sensible defaults:

```ruby
Blazer::Querygen.configure do |config|
  config.ai_model = "gpt-4o"  # or "gpt-4o-mini", "o1-preview", "gpt-5.2", etc.
  config.api_key = ENV["OPENAI_API_KEY"]
  config.timeout = 10
  config.max_retries = 3
  config.max_tables_in_context = 50
  config.sanitize_queries = true
  config.allowed_operations = [:select]
  config.excluded_tables = ["schema_migrations", "ar_internal_metadata"]
end
```

## Testing Strategy

- **Unit tests**: All core classes (AIClient, SchemaExtractor, PromptBuilder)
- **Integration tests**: Schema extraction with in-memory SQLite
- **Controller tests**: Skipped when Rails not loaded (gem-only testing)
- **API tests**: Skipped when `OPENAI_API_KEY` not set

Test setup uses in-memory SQLite with sample schema (users, products tables).

## Common Development Patterns

### Adding Support for New AI Models

1. Check if model uses reasoning parameters (like o1 or gpt-5.x)
2. Update `reasoning_model?` method in `AIClient` to detect the new model
3. Test with both sync and async generation modes

### Modifying Schema Context

Schema extraction happens in `SchemaExtractor`:
- Add new metadata extraction in `get_columns` or `get_tables`
- Update `format_schema` in `PromptBuilder` to include new metadata in prompt
- Be mindful of token limits when adding more context

### Debugging JavaScript Integration

Common issues:
- JavaScript not loading: Check asset precompile configuration
- UI not appearing: Verify `#statement-box` selector exists in Blazer version
- SQL not setting: Check if Ace Editor is present, verify `ace.edit()` works

Use browser console to debug: selectors are logged during initialization (can add debug logs temporarily).

## Important Files Not to Modify

- `config/routes.rb`: Empty by design. Routes injected via Engine initializer.
- `app/assets/javascripts/blazer/querygen.js`: Unused, kept for potential future use.

## Security Considerations

1. **Never send actual data to AI**: SchemaExtractor must only extract metadata
2. **SQL sanitization is regex-based**: Not foolproof, consider SQL parser for production
3. **API keys in environment**: Never commit API keys, always use ENV vars
4. **CSRF protection**: Inherited from Blazer::BaseController

# Blazer::Querygen

AI-powered SQL query generation for [Blazer](https://github.com/ankane/blazer). Generate SQL queries from natural language prompts using OpenAI.

## Features

- 🤖 Generate SQL queries from natural language descriptions
- 🔒 Secure: Only sends database schema (no actual data) to OpenAI
- 🛡️ Safe: Automatically blocks dangerous SQL operations (INSERT, UPDATE, DELETE, etc.)
- 🎯 Smart: Leverages table and column comments for better context
- ⚙️ Configurable: Support for multiple OpenAI models

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'blazer-querygen'
```

And then execute:

```bash
bundle install
```

Or install it yourself as:

```bash
gem install blazer-querygen
```

## Setup

1. Run the installer:

```bash
rails generate blazer:querygen:install
```

This will create an initializer at `config/initializers/blazer_querygen.rb`.

2. Set your OpenAI API key as an environment variable:

```bash
export OPENAI_API_KEY=your_api_key_here
```

Or add it to your `.env` file:

```
OPENAI_API_KEY=your_api_key_here
```

3. Restart your Rails server.

## Usage

1. Navigate to Blazer's "New Query" page
2. You'll see a new AI query generation interface above the SQL editor
3. Enter a natural language description of your query (e.g., "Show me the top 10 users by total orders in the last month")
4. Click "Generate Query with AI"
5. The generated SQL will appear in the editor
6. Review and execute the query

### Example Prompts

- "Find all active users who signed up in the last 7 days"
- "Show total revenue by product category for this year"
- "List the 5 most popular products by order count"
- "Get average order value grouped by month"

## Configuration

Edit `config/initializers/blazer_querygen.rb` to customize:

```ruby
Blazer::Querygen.configure do |config|
  # OpenAI Model (default: "gpt-5.2")
  # Options: "gpt-5.2", "gpt-4o", "gpt-4o-mini", "o1", "o1-mini"
  config.ai_model = "gpt-5.2"

  # API Key (use environment variable for security)
  config.api_key = ENV["OPENAI_API_KEY"]

  # Security: Sanitize queries (default: true)
  config.sanitize_queries = true

  # Only allow SELECT operations (default: [:select])
  config.allowed_operations = [:select]

  # Performance: API timeout in seconds (default: 10)
  config.timeout = 10

  # Performance: Retry attempts (default: 3)
  config.max_retries = 3

  # Performance: Max tables in schema context (default: 50)
  config.max_tables_in_context = 50

  # Schema: Include table comments (default: true)
  config.include_table_comments = true

  # Schema: Include column comments (default: true)
  config.include_column_comments = true

  # Schema: Exclude tables (default: migrations)
  config.excluded_tables = ["schema_migrations", "ar_internal_metadata"]
end
```

### Custom Prompts

You can customize both the system prompt and user prompt template to suit your specific needs.

**Note**: When using custom prompts, you are responsible for ensuring proper security instructions. The gem provides SQL sanitization (`sanitize_queries = true` by default) as a safety net, but proper AI instructions are recommended.

#### Custom System Prompt

```ruby
# Override the default system prompt
config.system_prompt = <<~PROMPT
  You are an SQL query generator.

  IMPORTANT: Generate only SELECT statements.
  Do not generate INSERT, UPDATE, DELETE, DROP, CREATE, ALTER, or TRUNCATE.

  [Your additional custom instructions here]
PROMPT
```

#### Custom User Prompt Template

```ruby
# Override how user requests and schema are formatted
# Receives two parameters: user_input (String), formatted_schema (String)
config.user_prompt_template = lambda do |user_input, formatted_schema|
  <<~PROMPT
    Generate SQL for: #{user_input}

    Tables:
    #{formatted_schema}

    Output only the SQL query.
  PROMPT
end
```

## Security

- **Schema Only**: Only database schema information (table names, column names, types, and comments) is sent to OpenAI. No actual data is transmitted.
- **SQL Sanitization**: Generated queries are automatically checked for dangerous operations (INSERT, UPDATE, DELETE, DROP, etc.).
- **SELECT Only**: By default, only SELECT statements are allowed.
- **API Key**: Store your OpenAI API key securely using environment variables.

## How It Works

1. **Schema Extraction**: The gem extracts your database schema (tables, columns, types, comments) without accessing actual data.
2. **Prompt Construction**: A detailed prompt is constructed with the schema and your natural language request.
3. **AI Generation**: OpenAI generates an appropriate SQL query.
4. **Sanitization**: The query is validated to ensure it only contains safe operations.
5. **Display**: The generated SQL is displayed in Blazer's editor for review.

## API Endpoints

The gem adds the following endpoints to your application:

- `POST /blazer/prompts/run` - Generate a SQL query from a prompt
- `GET /blazer/querygen/health` - Check configuration status

## Future Enhancements

Planned features for future releases:

- Query explanation feature (explain existing SQL in plain language)
- Multi-language support (Japanese, etc.)
- Support for Anthropic Claude
- Query optimization suggestions
- Query history and favorites

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake test` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/SonicGarden/blazer-querygen. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/SonicGarden/blazer-querygen/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Blazer::Querygen project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/SonicGarden/blazer-querygen/blob/master/CODE_OF_CONDUCT.md).

## Acknowledgments

- [Blazer](https://github.com/ankane/blazer) by Andrew Kane
- Inspired by [blazer-plus](https://github.com/SonicGarden/blazer-plus)
- Built with [ruby-openai](https://github.com/alexrudall/ruby-openai)

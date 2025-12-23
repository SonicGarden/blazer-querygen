# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

# Load testing dependencies
require "minitest/autorun"
require "active_support"
require "active_support/test_case"
require "active_record"

# Load the gem
require "blazer/querygen"

# Configure test environment
if defined?(ActiveRecord)
  # Use in-memory SQLite for tests
  ActiveRecord::Base.establish_connection(
    adapter: "sqlite3",
    database: ":memory:"
  )

  # Create a simple test schema
  ActiveRecord::Schema.define do
    create_table :users, force: true do |t|
      t.string :email
      t.string :name
      t.timestamps
    end

    create_table :products, force: true do |t|
      t.string :name
      t.decimal :price
      t.timestamps
    end
  end
end

# Configure Blazer::Querygen
Blazer::Querygen.configure do |config|
  config.api_key = ENV["OPENAI_API_KEY"]
  config.ai_model = "gpt-4o-mini" # Use cheaper model for tests
  config.timeout = 30
  config.max_tables_in_context = 10
end

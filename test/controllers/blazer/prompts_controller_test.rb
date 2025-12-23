# frozen_string_literal: true

require "test_helper"

# Skip controller tests if Rails is not loaded
unless defined?(ActionDispatch::IntegrationTest)
  puts "Skipping PromptsController tests (Rails not loaded)"
  return
end

module Blazer
  class PromptsControllerTest < ActionDispatch::IntegrationTest
    setup do
      # Mock Blazer authentication if needed
      # You may need to adjust this based on your Blazer configuration
    end

    test "health endpoint returns configured status" do
      get blazer_querygen_health_url
      assert_response :success

      json = JSON.parse(response.body)
      assert json.key?("status")
      assert json.key?("success")
    end

    test "run requires prompt parameter" do
      post blazer_run_prompt_url, params: { prompt: "" }, as: :json
      assert_response :unprocessable_entity

      json = JSON.parse(response.body)
      assert_equal false, json["success"]
      assert json["error"].present?
    end

    test "run generates query with valid prompt" do
      skip "Skipping live API test - mock needed"

      # This test would require mocking the AI client
      post blazer_run_prompt_url, params: {
        prompt: "Show me all users"
      }, as: :json

      assert_response :success
      json = JSON.parse(response.body)
      assert json["success"]
      assert json["sql"].present?
    end

    test "sanitize_sql blocks dangerous operations" do
      controller = PromptsController.new

      dangerous_sqls = [
        "INSERT INTO users VALUES (1, 'test')",
        "UPDATE users SET name = 'test'",
        "DELETE FROM users",
        "DROP TABLE users",
        "CREATE TABLE test (id INT)",
        "ALTER TABLE users ADD COLUMN test VARCHAR(255)",
        "TRUNCATE TABLE users"
      ]

      dangerous_sqls.each do |sql|
        assert_raises(Blazer::Querygen::Error) do
          controller.send(:sanitize_sql, sql)
        end
      end
    end

    test "sanitize_sql allows SELECT queries" do
      controller = PromptsController.new

      safe_sqls = [
        "SELECT * FROM users",
        "SELECT id, name FROM products WHERE price > 100",
        "SELECT COUNT(*) FROM orders"
      ]

      safe_sqls.each do |sql|
        assert_nothing_raised do
          result = controller.send(:sanitize_sql, sql)
          assert_equal sql, result
        end
      end
    end
  end
end

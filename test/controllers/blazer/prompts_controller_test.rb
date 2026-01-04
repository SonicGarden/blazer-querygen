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

    test "run handles UnsafeQueryError with 422 status" do
      skip "Requires mocking QueryGenerator to raise UnsafeQueryError"
      # This test would require mocking QueryGenerator.generate to raise UnsafeQueryError
      # and verify that the controller returns 422 Unprocessable Entity status
    end

    test "run handles ConfigurationError with 503 status" do
      skip "Requires mocking QueryGenerator to raise ConfigurationError"
      # This test would require mocking QueryGenerator.generate to raise ConfigurationError
      # and verify that the controller returns 503 Service Unavailable status
    end

    test "run handles APIError with 500 status" do
      skip "Requires mocking QueryGenerator to raise APIError"
      # This test would require mocking QueryGenerator.generate to raise APIError
      # and verify that the controller returns 500 Internal Server Error status
    end

    test "run handles TimeoutError with 408 status" do
      skip "Requires mocking QueryGenerator to raise TimeoutError"
      # This test would require mocking QueryGenerator.generate to raise TimeoutError
      # and verify that the controller returns 408 Request Timeout status
    end
  end
end

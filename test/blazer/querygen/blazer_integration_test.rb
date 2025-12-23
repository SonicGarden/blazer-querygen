# frozen_string_literal: true

require "test_helper"

module Blazer
  module Querygen
    class BlazerIntegrationTest < ActiveSupport::TestCase
      test "can extract schema from ActiveRecord connection" do
        extractor = SchemaExtractor.new
        schema = extractor.extract

        assert schema.is_a?(Array)
        assert schema.any?

        # Check that we got the test tables
        table_names = schema.map { |t| t[:name] }
        assert_includes table_names, "users"
        assert_includes table_names, "products"
      end

      test "schema includes column information" do
        extractor = SchemaExtractor.new
        schema = extractor.extract

        users_table = schema.find { |t| t[:name] == "users" }
        assert users_table

        column_names = users_table[:columns].map { |c| c[:name] }
        assert_includes column_names, "id"
        assert_includes column_names, "email"
        assert_includes column_names, "name"
      end

      test "can get connection without data source name" do
        extractor = SchemaExtractor.new
        connection = extractor.send(:get_connection, nil)

        assert connection
        assert_respond_to connection, :tables
      end
    end
  end
end

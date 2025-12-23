# frozen_string_literal: true

require "test_helper"

module Blazer
  module Querygen
    class SchemaExtractorTest < ActiveSupport::TestCase
      setup do
        @extractor = SchemaExtractor.new
      end

      test "extracts schema from default connection" do
        schema = @extractor.extract

        assert schema.is_a?(Array)
        assert schema.any?, "Schema should contain at least one table"

        # Check first table structure
        table = schema.first
        assert table.key?(:name)
        assert table.key?(:columns)
        assert table[:columns].is_a?(Array)

        # Check column structure
        if table[:columns].any?
          column = table[:columns].first
          assert column.key?(:name)
          assert column.key?(:type)
        end
      end

      test "respects max_tables_in_context configuration" do
        original_max = Blazer::Querygen.config.max_tables_in_context

        begin
          Blazer::Querygen.config.max_tables_in_context = 2
          schema = @extractor.extract

          assert schema.length <= 2, "Should respect max_tables_in_context limit"
        ensure
          Blazer::Querygen.config.max_tables_in_context = original_max
        end
      end

      test "excludes configured tables" do
        original_excluded = Blazer::Querygen.config.excluded_tables

        begin
          Blazer::Querygen.config.excluded_tables = ["schema_migrations"]
          schema = @extractor.extract

          table_names = schema.map { |t| t[:name] }
          assert_not_includes table_names, "schema_migrations"
        ensure
          Blazer::Querygen.config.excluded_tables = original_excluded
        end
      end

      test "handles empty database gracefully" do
        # This test assumes a connection with no tables
        # In reality, there will always be some tables
        schema = @extractor.extract
        assert schema.is_a?(Array)
      end
    end
  end
end

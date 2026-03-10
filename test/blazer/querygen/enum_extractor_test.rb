# frozen_string_literal: true

require "test_helper"

module Blazer
  module Querygen
    class EnumExtractorTest < ActiveSupport::TestCase
      setup do
        @extractor = EnumExtractor.new
      end

      test "returns empty hash when include_enum_values is false" do
        original = Blazer::Querygen.config.include_enum_values

        begin
          Blazer::Querygen.config.include_enum_values = false
          result = @extractor.extract

          assert_equal({}, result)
        ensure
          Blazer::Querygen.config.include_enum_values = original
        end
      end

      test "extracts ActiveRecord enums from models" do
        result = @extractor.extract

        assert result.key?("orders"), "Should include orders table"
        assert result["orders"].key?("status"), "Should include status enum"
        assert_equal({ "pending" => 0, "processing" => 1, "shipped" => 2, "delivered" => 3 },
                     result["orders"]["status"])
      end

      test "extracts multiple enums from same model" do
        result = @extractor.extract

        assert result["orders"].key?("priority"), "Should include priority enum"
        assert_equal({ "low" => 0, "medium" => 1, "high" => 2 },
                     result["orders"]["priority"])
      end

      test "does not include tables without enums" do
        result = @extractor.extract

        # Only check that tables with no enum defined on Order are excluded
        refute result.key?("products"), "Should not include products table (no enums)"
      end

      test "does not mutate model defined_enums" do
        original_enums = Order.defined_enums.deep_dup

        @extractor.extract

        assert_equal original_enums, Order.defined_enums
      end

      test "handles enumerize attributes when available" do
        mock_attr = Object.new
        mock_attr.define_singleton_method(:name) { :role }
        mock_attr.define_singleton_method(:values) { %w[admin user guest] }

        # Create a mock model without inheriting ActiveRecord::Base to avoid polluting descendants
        mock_model = Object.new
        mock_model.define_singleton_method(:abstract_class?) { false }
        mock_model.define_singleton_method(:table_name) { "users" }
        mock_model.define_singleton_method(:defined_enums) { {} }
        mock_model.define_singleton_method(:enumerized_attributes) { [mock_attr] }

        # Use a custom extractor that injects our mock model
        extractor = EnumExtractor.new
        extractor.define_singleton_method(:load_models) { [Order, mock_model] }

        result = extractor.extract

        assert result.key?("users"), "Should include users table from enumerize"
        assert_equal({ "admin" => "admin", "user" => "user", "guest" => "guest" },
                     result["users"]["role"])
      end

      test "gracefully handles models without tables" do
        mock_abstract = Object.new
        mock_abstract.define_singleton_method(:abstract_class?) { true }
        mock_abstract.define_singleton_method(:table_name) { raise StandardError, "no table" }

        extractor = EnumExtractor.new
        extractor.define_singleton_method(:load_models) { [Order, mock_abstract] }

        result = extractor.extract

        assert_kind_of Hash, result, "Should still return a hash"
        assert result.key?("orders"), "Should still extract Order enums"
      end
    end
  end
end

# frozen_string_literal: true

require "test_helper"

module Blazer
  module Querygen
    class QueryGeneratorTest < ActiveSupport::TestCase
      setup do
        @generator = QueryGenerator.new
      end

      test "sanitize blocks INSERT statements" do
        assert_raises(QueryGenerator::UnsafeQueryError) do
          @generator.send(:sanitize, "INSERT INTO users VALUES (1, 'test')")
        end
      end

      test "sanitize blocks UPDATE statements" do
        assert_raises(QueryGenerator::UnsafeQueryError) do
          @generator.send(:sanitize, "UPDATE users SET email = 'test'")
        end
      end

      test "sanitize blocks DELETE statements" do
        assert_raises(QueryGenerator::UnsafeQueryError) do
          @generator.send(:sanitize, "DELETE FROM users")
        end
      end

      test "sanitize blocks DROP statements" do
        assert_raises(QueryGenerator::UnsafeQueryError) do
          @generator.send(:sanitize, "DROP TABLE users")
        end
      end

      test "sanitize blocks CREATE statements" do
        assert_raises(QueryGenerator::UnsafeQueryError) do
          @generator.send(:sanitize, "CREATE TABLE test (id INT)")
        end
      end

      test "sanitize blocks ALTER statements" do
        assert_raises(QueryGenerator::UnsafeQueryError) do
          @generator.send(:sanitize, "ALTER TABLE users ADD COLUMN test VARCHAR(255)")
        end
      end

      test "sanitize blocks TRUNCATE statements" do
        assert_raises(QueryGenerator::UnsafeQueryError) do
          @generator.send(:sanitize, "TRUNCATE TABLE users")
        end
      end

      test "sanitize blocks GRANT statements" do
        assert_raises(QueryGenerator::UnsafeQueryError) do
          @generator.send(:sanitize, "GRANT ALL ON users TO some_user")
        end
      end

      test "sanitize blocks REVOKE statements" do
        assert_raises(QueryGenerator::UnsafeQueryError) do
          @generator.send(:sanitize, "REVOKE ALL ON users FROM some_user")
        end
      end

      test "sanitize allows SELECT statements" do
        safe_sql = "SELECT * FROM users"
        assert_nothing_raised do
          result = @generator.send(:sanitize, safe_sql)
          assert_equal safe_sql, result
        end
      end

      test "sanitize allows SELECT with WHERE clause" do
        safe_sql = "SELECT id, email FROM users WHERE created_at > '2024-01-01'"
        assert_nothing_raised do
          result = @generator.send(:sanitize, safe_sql)
          assert_equal safe_sql, result
        end
      end

      test "sanitize allows SELECT with JOINs" do
        safe_sql = "SELECT u.id, p.name FROM users u JOIN products p ON u.id = p.user_id"
        assert_nothing_raised do
          result = @generator.send(:sanitize, safe_sql)
          assert_equal safe_sql, result
        end
      end

      test "sanitize respects configuration setting" do
        original_setting = Blazer::Querygen.config.sanitize_queries

        begin
          # Disable sanitization
          Blazer::Querygen.config.sanitize_queries = false

          # Should not raise even with dangerous SQL
          dangerous_sql = "DROP TABLE users"
          assert_nothing_raised do
            result = @generator.send(:sanitize, dangerous_sql)
            assert_equal dangerous_sql, result
          end
        ensure
          Blazer::Querygen.config.sanitize_queries = original_setting
        end
      end

      test "sanitize is case insensitive" do
        dangerous_sqls = [
          "insert into users values (1)",
          "InSeRt INTO users VALUES (1)",
          "INSERT into users values (1)"
        ]

        dangerous_sqls.each do |sql|
          assert_raises(QueryGenerator::UnsafeQueryError) do
            @generator.send(:sanitize, sql)
          end
        end
      end

      test "sanitize catches dangerous keywords in comments" do
        # Edge case: SQL with comment containing dangerous keyword
        # This is acceptable - comments shouldn't be executed
        sql_with_comment = "SELECT * FROM users -- Don't DROP this table"

        assert_raises(QueryGenerator::UnsafeQueryError) do
          @generator.send(:sanitize, sql_with_comment)
        end
      end
    end
  end
end

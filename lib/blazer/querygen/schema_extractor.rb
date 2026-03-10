# frozen_string_literal: true

module Blazer
  module Querygen
    # Extracts database schema information without accessing actual data
    class SchemaExtractor # rubocop:disable Metrics/ClassLength
      def extract(data_source_name = nil) # rubocop:disable Metrics/MethodLength
        connection = get_connection(data_source_name)
        tables = get_tables(connection)

        schema = tables.filter_map do |table_name|
          next if excluded?(table_name)

          {
            name: table_name,
            comment: get_table_comment(connection, table_name),
            columns: get_columns(connection, table_name)
          }
        end

        # Enrich with enum metadata from models
        schema = enrich_with_enums(schema)

        # Limit number of tables for API efficiency
        schema.take(Blazer::Querygen.config.max_tables_in_context)
      end

      private

      def get_connection(_data_source_name)
        # For now, always use ActiveRecord's default connection
        # This works for most cases where Blazer is using the same database as the Rails app
        # Future enhancement: Support multiple Blazer data sources properly
        raise Blazer::Querygen::Error, "No database connection available" unless defined?(ActiveRecord::Base)

        ActiveRecord::Base.connection

        # TODO: Support Blazer data sources properly
        # The challenge is that Blazer::DataSource doesn't expose the connection directly
        # We may need to use Blazer's run_statement method or extract connection differently
      end

      def get_tables(connection)
        connection.tables.sort
      end

      def get_columns(connection, table_name)
        connection.columns(table_name).map do |column|
          {
            name: column.name,
            type: column.type.to_s,
            null: column.null,
            comment: get_column_comment(connection, table_name, column.name)
          }
        end
      end

      def get_table_comment(connection, table_name) # rubocop:disable Metrics/MethodLength
        return nil unless Blazer::Querygen.config.include_table_comments

        adapter = connection.adapter_name.downcase
        case adapter
        when "postgresql"
          fetch_postgres_table_comment(connection, table_name)
        when "mysql", "mysql2", "trilogy"
          fetch_mysql_table_comment(connection, table_name)
        end
      rescue StandardError => e
        Rails.logger.debug("Failed to fetch table comment for #{table_name}: #{e.message}") if defined?(Rails)
        nil
      end

      def get_column_comment(connection, table_name, column_name) # rubocop:disable Metrics/MethodLength
        return nil unless Blazer::Querygen.config.include_column_comments

        adapter = connection.adapter_name.downcase
        case adapter
        when "postgresql"
          fetch_postgres_column_comment(connection, table_name, column_name)
        when "mysql", "mysql2", "trilogy"
          fetch_mysql_column_comment(connection, table_name, column_name)
        end
      rescue StandardError => e
        if defined?(Rails)
          Rails.logger.debug("Failed to fetch column comment for #{table_name}.#{column_name}: #{e.message}")
        end
        nil
      end

      def fetch_postgres_table_comment(connection, table_name)
        result = connection.execute(<<~SQL)
          SELECT obj_description(to_regclass('#{connection.quote_table_name(table_name)}'))
        SQL
        result.first&.values&.first
      end

      def fetch_mysql_table_comment(connection, table_name)
        result = connection.execute(<<~SQL)
          SELECT table_comment
          FROM information_schema.tables
          WHERE table_schema = DATABASE()
          AND table_name = #{connection.quote(table_name)}
        SQL
        comment = result.first&.first
        comment if comment && !comment.empty?
      end

      def fetch_postgres_column_comment(connection, table_name, column_name)
        result = connection.execute(<<~SQL)
          SELECT col_description(
            to_regclass('#{connection.quote_table_name(table_name)}')::oid,
            (SELECT ordinal_position
             FROM information_schema.columns
             WHERE table_name=#{connection.quote(table_name)}
             AND column_name=#{connection.quote(column_name)})
          )
        SQL
        result.first&.values&.first
      end

      def fetch_mysql_column_comment(connection, table_name, column_name)
        result = connection.execute(<<~SQL)
          SELECT column_comment
          FROM information_schema.columns
          WHERE table_schema = DATABASE()
          AND table_name = #{connection.quote(table_name)}
          AND column_name = #{connection.quote(column_name)}
        SQL
        comment = result.first&.first
        comment if comment && !comment.empty?
      end

      def enrich_with_enums(schema) # rubocop:disable Metrics/MethodLength
        return schema unless Blazer::Querygen.config.include_enum_values

        enum_mapping = EnumExtractor.new.extract
        return schema if enum_mapping.empty?

        schema.map do |table|
          table_enums = enum_mapping[table[:name]]
          next table unless table_enums

          enriched_columns = table[:columns].map do |col|
            col_enums = table_enums[col[:name]]
            col_enums ? { **col, enums: col_enums } : col
          end

          { **table, columns: enriched_columns }
        end
      end

      def excluded?(table_name)
        Blazer::Querygen.config.excluded_tables.include?(table_name)
      end
    end
  end
end

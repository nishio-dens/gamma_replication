# frozen_string_literal: true

module GammaReplication
  module Parser
    class DataParser
      def initialize(data_yaml_path, hook_root_dir, in_client, out_client, apply: false)
        @data_settings = YAML.load_file(data_yaml_path).map(&:with_indifferent_access)
        @hook_root_dir = hook_root_dir
        @in_client = in_client
        @out_client = out_client
        @apply = apply
      end

      def gamma_tables
        exist_tables = database_exist_tables
        @data_settings.flat_map { |d| parse_data_settings(d[:data], exist_tables) }
      end

      private

      def parse_data_settings(data, exist_tables)
        tables = find_target_tables(data, exist_tables)
        tables.map { |t| apply_table_settings(t, data) }
      end

      def find_target_tables(data, exist_tables)
        if Array(data[:table]).join == "*"
          without = Array(data[:table_without]) || []
          exist_tables.reject { |v| without.include?(v.table_name) }
        else
          Array(data[:table]).map do |table_name|
            exist_tables.find { |t| t.table_name == table_name }
          end.compact
        end
      end

      def apply_table_settings(table, data)
        table.tap do |t|
          t.hooks = data[:hooks].present? ? parse_hooks(data[:hooks], t) : []
        end
      end

      def database_exist_tables
        in_tables = select_table_definitions(@in_client)
        out_tables = select_table_definitions(@out_client)

        (in_tables + out_tables).uniq.map do |table|
          build_table_info(table, in_tables, out_tables)
        end
      end

      def build_table_info(table, in_tables, out_tables)
        GammaReplication::Table.new.tap do |t|
          t.table_name = table
          t.in_exist = in_tables.include?(table)
          t.out_exist = out_tables.include?(table)
          t.in_exist_columns = select_column_definitions(@in_client, table)
          t.out_exist_columns = select_column_definitions(@out_client, table)
        end
      end

      def select_table_definitions(client)
        query = build_table_query(client)
        client.schema_client.query(query).to_a.map { |v| v["TABLE_NAME"] }
      end

      def build_table_query(client)
        database = client.schema_client.escape(client.config[:database])
        <<~SQL
          SELECT
            *
          FROM
            TABLES
          INNER JOIN
            COLLATION_CHARACTER_SET_APPLICABILITY CCSA
          ON
            TABLES.TABLE_COLLATION = CCSA.COLLATION_NAME
          WHERE
            TABLE_SCHEMA = '#{database}'
          ORDER BY
            TABLE_NAME
        SQL
      end

      def select_column_definitions(client, table_name)
        query = build_column_query(client, table_name)
        client.schema_client.query(query).to_a.map { |v| v["COLUMN_NAME"] }
      end

      def build_column_query(client, table_name)
        database = client.schema_client.escape(client.config[:database])
        escaped_table = client.schema_client.escape(table_name)
        <<~SQL
          SELECT
            *
          FROM
            COLUMNS
          WHERE
            TABLE_SCHEMA = '#{database}'
            AND TABLE_NAME = '#{escaped_table}'
          ORDER BY
            TABLE_NAME, ORDINAL_POSITION
        SQL
      end

      def parse_hooks(hooks, table)
        hooks = Array(hooks)
        hooks.flat_map do |hook|
          type = determine_hook_type(hook)
          create_hooks_by_type(type, hook, table)
        end.compact
      end

      def determine_hook_type(hook)
        if hook[:row].present?
          :row
        elsif hook[:column].present?
          :column
        end
      end

      def create_hooks_by_type(type, hook, table)
        case type
        when :row
          create_row_hooks(hook[:row], table)
        when :column
          create_column_hooks(hook[:column], table)
        else
          raise "Unknown Hook Type"
        end
      end

      def create_row_hooks(options, table)
        validate_row_hook_options!(options, table)
        Array(options[:scripts]).map do |script|
          build_hook(:row, nil, script)
        end
      end

      def create_column_hooks(options, table)
        validate_column_hook_options!(options, table)
        column_names = Array(options[:name])
        scripts = Array(options[:scripts])
        column_names.product(scripts).map do |column_name, script|
          build_hook(:column, column_name, script)
        end
      end

      def build_hook(type, column_name, script)
        GammaReplication::Hook.new.tap do |h|
          h.hook_type = type
          h.column_name = column_name
          h.script_path = script
          h.root_dir = @hook_root_dir
          h.apply = @apply
        end
      end

      def validate_row_hook_options!(options, table)
        return if options[:scripts].present?

        raise "Required scripts arguments. table: #{table.table_name}, hook_type: row"
      end

      def validate_column_hook_options!(options, table)
        unless options[:name].present?
          raise "Required column name arguments. table: #{table.table_name}, hook_type: column"
        end
        return if options[:scripts].present?

        raise "Required scripts arguments. table: #{table.table_name}, hook_type: column"
      end
    end
  end
end

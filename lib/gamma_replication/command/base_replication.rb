# frozen_string_literal: true

module GammaReplication
  module Command
    class BaseReplication < Base
      def initialize(opts)
        super()
        setup_database(opts)
        setup_parser(opts)
        setup_maxwell(opts)
        initialize_stats
        @enable_stats = opts[:enable_stats].nil? ? true : opts[:enable_stats]
        @stats_interval = (opts[:stats_interval] || 3 * 60 * 60).to_i # Default: 3 hours in seconds
      end

      def execute
        tables = @data_parser.gamma_tables
        output_setting_warning(tables)

        @table_settings = tables.each_with_object({}) do |table, hash|
          hash[table.table_name] = table
        end
        before_start if respond_to?(:before_start)

        setup_stats_reporter if @enable_stats

        @maxwell_client.start do |data|
          process_maxwell_data(data)
        end
      end

      private

      def initialize_stats
        @stats = {
          total: { insert: 0, update: 0, delete: 0 },
          by_table: {}
        }
        @stats_mutex = Mutex.new
      end

      def setup_stats_reporter
        @stats_thread = Thread.new do
          loop do
            sleep @stats_interval
            output_stats
            reset_stats
          end
        end
      end

      def update_stats(table_name, operation)
        return unless @enable_stats

        @stats_mutex.synchronize do
          @stats[:total][operation] += 1
          @stats[:by_table][table_name] ||= { insert: 0, update: 0, delete: 0 }
          @stats[:by_table][table_name][operation] += 1
        end
      end

      def reset_stats
        @stats_mutex.synchronize do
          initialize_stats
        end
      end

      def output_stats
        @stats_mutex.synchronize do
          total_stats = "Total[ins:#{@stats[:total][:insert]} | upd:#{@stats[:total][:update]} | del:#{@stats[:total][:delete]}]"

          table_stats = @stats[:by_table].map do |table, counts|
            "#{table}[ins:#{counts[:insert]} | upd:#{counts[:update]} | del:#{counts[:delete]}]"
          end.join("\n")

          logger.info("STATS | #{total_stats}\n#{table_stats}")
        end
      end

      def setup_database(opts)
        @database_settings = GammaReplication::DatabaseSettings.new(opts[:settings])
        @in_client = GammaReplication::DatabaseConnector::MysqlConnector.new(@database_settings.in_database)
        @out_client = GammaReplication::DatabaseConnector::MysqlConnector.new(@database_settings.out_database)
      end

      def setup_parser(opts)
        @hook_root_dir = opts[:hook_dir] || "."
        @data_parser = GammaReplication::Parser::DataParser.new(opts[:data], @hook_root_dir, @in_client, @out_client,
                                                                apply: apply_mode?)
      end

      def setup_maxwell(opts)
        @maxwell_client = GammaReplication::MaxwellClient.new(
          config_path: opts[:maxwell_config] || "config.properties"
        )
      end

      def process_maxwell_data(data)
        return unless should_process_data?(data)

        process_data_by_type(data)
      rescue StandardError => e
        logger.error(e)
      end

      def should_process_data?(data)
        table_name = data["table"]
        table_setting = @table_settings[table_name]
        return false unless table_setting
        return false if @database_settings.in_database["database"] != data["database"]

        true
      end

      def process_data_by_type(data)
        table_setting = @table_settings[data["table"]]
        case data["type"]
        when "insert"
          return unless data["data"].present?

          update_stats(data["table"], :insert)
          process_insert(table_setting, data)
        when "update"
          return unless data["data"].present?

          update_stats(data["table"], :update)
          process_update(table_setting, data)
        when "delete"
          return unless data["old"].present?

          update_stats(data["table"], :delete)
          process_delete(table_setting, data)
        end
      rescue StandardError => e
        logger.error("Error processing data: #{data["table"]} - #{e.message}")
      end

      def process_insert(table_setting, data)
        record = data["data"]
        processed_record = apply_hooks(table_setting, record)

        columns = processed_record.keys.map { |k| "`#{k}`" }
        values = processed_record.values.map { |v| format_value(v) }

        query = "INSERT INTO #{table_setting.table_name} (#{columns.join(",")}) VALUES (#{values.join(",")})"
        execute_query(query)
      end

      def process_update(table_setting, data)
        record = data["data"]
        old_record = data["old"]
        processed_record = apply_hooks(table_setting, record)

        set_clause = processed_record.map { |k, v| "`#{k}` = #{format_value(v)}" }.join(",")
        where_clause = build_where_clause(old_record, record, table_setting.primary_key)

        query = "UPDATE #{table_setting.table_name} SET #{set_clause} WHERE #{where_clause}"
        execute_query(query)
      end

      def process_delete(table_setting, data)
        old_record = data["old"]
        return unless old_record.present? && old_record[table_setting.primary_key].present?

        where_clause = build_where_clause(old_record, nil, table_setting.primary_key)
        query = "DELETE FROM #{table_setting.table_name} WHERE #{where_clause}"
        execute_query(query)
      end

      def apply_hooks(table_setting, record)
        result = record.dup
        table_setting.hooks.each do |hook|
          result = hook.execute_script(result)
        end
        result
      end

      def build_where_clause(old_record, new_record, primary_key)
        if old_record.present? && old_record[primary_key].present?
          "`#{primary_key}` = #{format_value(old_record[primary_key])}"
        elsif new_record.present? && new_record[primary_key].present?
          "`#{primary_key}` = #{format_value(new_record[primary_key])}"
        else
          logger.error("Primary key not found. old_record: #{old_record.inspect}, new_record: #{new_record.inspect}")
          raise "Primary key '#{primary_key}' not found in record"
        end
      end

      def format_value(value)
        case value
        when nil
          "NULL"
        when Numeric
          value.to_s
        when Time
          "'#{value.strftime("%Y-%m-%d %H:%M:%S")}'"
        else
          if json_column?(value)
            sanitized_value = sanitize_json(value)
            "'#{@out_client.client.escape(sanitized_value)}'"
          else
            "'#{@out_client.client.escape(value.to_s)}'"
          end
        end
      end

      def json_column?(value)
        value.is_a?(String) && (value.start_with?("{") || value.start_with?("["))
      end

      def sanitize_json(value)
        JSON.parse(value)
        value
      rescue JSON::ParserError => e
        sanitized = value.gsub(/([{,]\s*)(\w+)(\s*:)/) do
          "#{::Regexp.last_match(1)}\"#{::Regexp.last_match(2)}\"#{::Regexp.last_match(3)}"
        end
        sanitized = sanitized.gsub(/:\s*([^",\s\d\[\]{}-].*?)(,|\}|$)/) do
          ": \"#{::Regexp.last_match(1)}\"#{::Regexp.last_match(2)}"
        end
        begin
          JSON.parse(sanitized)
          sanitized
        rescue JSON::ParserError
          value.to_json
        end
      end

      def apply_mode?
        raise NotImplementedError, "#{self.class} must implement #apply_mode?"
      end

      def execute_query(query)
        raise NotImplementedError, "#{self.class} must implement #execute_query"
      end
    end
  end
end

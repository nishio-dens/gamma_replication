# frozen_string_literal: true

module GammaReplication
  module Command
    class Base
      def gamma_tables(_in_client, _out_client, data_parser)
        data_parser.gamma_tables
      end

      def output_setting_warning(tables)
        find_duplicate_tables(tables).each do |table_name|
          log_duplicate_table_warning(table_name)
        end
      end

      private

      def find_duplicate_tables(tables)
        tables
          .group_by(&:table_name)
          .select { |_, group| group.size > 1 }
          .keys
      end

      def log_duplicate_table_warning(table_name)
        logger.warn("Table *#{table_name}* settings are duplicated. Please review your data settings.")
      end

      def logger
        @logger ||= Logger.new($stdout)
      end
    end
  end
end

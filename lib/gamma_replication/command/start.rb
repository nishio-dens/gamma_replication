# frozen_string_literal: true

module GammaReplication
  module Command
    class Start < BaseReplication
      def initialize(opts)
        super
        @force_mode = opts[:force]
        @out_client.client.query("SET FOREIGN_KEY_CHECKS = 0") if @force_mode
      end

      def apply_mode?
        true
      end

      def execute_query(query)
        logger.info("Executing: #{query}") if ENV["DEBUG"]
        @out_client.client.query(query)
      rescue StandardError => e
        error_message = e.message.to_s.split("\n").first
        logger.error("Query execution failed: #{error_message.gsub(/\s+/, " ")}")
      end

      def finalize
        @out_client.client.query("SET FOREIGN_KEY_CHECKS = 1") if @force_mode
        super
      end
    end
  end
end

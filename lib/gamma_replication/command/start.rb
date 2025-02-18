# frozen_string_literal: true

module GammaReplication
  module Command
    class Start < BaseReplication
      def initialize(*)
        super
        @out_client.client.query("SET FOREIGN_KEY_CHECKS = 0")
      end

      def apply_mode?
        true
      end

      def execute_query(query)
        logger.info("Executing: #{query}") if ENV["DEBUG"]
        @out_client.client.query(query)
      rescue StandardError => e
        logger.error("Query execution failed: #{e.message}")
      end

      def finalize
        @out_client.client.query("SET FOREIGN_KEY_CHECKS = 1")
        super
      end
    end
  end
end

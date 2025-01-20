# frozen_string_literal: true

module GammaReplication
  module Command
    class Dryrun < BaseReplication
      def before_start
        logger.info("Starting DryRun mode...")
      end

      private

      def apply_mode?
        false
      end

      def execute_query(query)
        logger.info("DryRun: #{query}")
      end
    end
  end
end

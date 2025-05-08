# frozen_string_literal: true

module GammaReplication
  module Command
    class Start < BaseReplication
      FATAL_ERROR_KEYWORDS = [
        /out of memory/i,
        /cannot allocate memory/i,
        /memory allocation failed/i,
        /no space left on device/i,
        /disk full/i,
        /too many open files/i,
        /segmentation fault/i,
        /bus error/i,
        /killed/i,
        /can't connect to mysql server/i,
        /lost connection to mysql server/i,
        /mysql server has gone away/i,
        /permission denied/i,
        /read-only file system/i,
        /network is unreachable/i,
        /connection refused/i,
        /connection timed out/i
      ].freeze

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
        retries = 0
        begin
          @out_client.client.query(query)
        rescue StandardError => e
          error_message = e.message.to_s.split("\n").first
          log_msg = "Query execution failed: #{error_message.gsub(/\s+/, " ")}"
          logger.error(log_msg)

          if fatal_error?(error_message)
            retries += 1
            if retries < 3
              logger.warn("Retrying due to fatal error (attempt #{retries})...")
              sleep 2**retries
              retry
            else
              logger.fatal("Fatal: unrecoverable error after #{retries} attempts. Exiting. Error: #{log_msg}")
              exit(1)
            end
          end
        end
      end

      def fatal_error?(msg)
        FATAL_ERROR_KEYWORDS.any? { |pattern| msg =~ pattern }
      end

      def finalize
        @out_client.client.query("SET FOREIGN_KEY_CHECKS = 1") if @force_mode
        super
      end
    end
  end
end

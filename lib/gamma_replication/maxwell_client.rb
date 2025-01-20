# frozen_string_literal: true

require "json"
require "open3"

module GammaReplication
  class MaxwellClient
    attr_reader :config_path, :maxwell_path

    def initialize(config_path:, maxwell_path: "./maxwell")
      @config_path = config_path
      @maxwell_path = maxwell_path
    end

    def start(&block)
      cmd = "#{maxwell_path}/bin/maxwell --config #{config_path}"

      IO.popen(cmd) do |io|
        io.each do |line|
          data = JSON.parse(line.strip)
          block.call(data) if block_given?
        rescue JSON::ParserError => e
          logger.error("Failed to parse Maxwell output: #{e.message}")
        end
      end
    end

    private

    def logger
      @logger ||= Logger.new($stdout)
    end
  end
end

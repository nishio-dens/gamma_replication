# frozen_string_literal: true

require "mysql2"

module GammaReplication
  module DatabaseConnector
    class MysqlConnector
      DEFAULT_PORT = 3306

      attr_reader :config

      def initialize(config)
        @config = config
      end

      def client(database_name = @config[:database])
        @client ||= Mysql2::Client.new(
          host: @config[:host],
          port: @config[:port] || DEFAULT_PORT,
          username: @config[:username],
          password: @config[:password] || "",
          database: database_name
        )
      end

      def schema_client
        @schema_client ||= Mysql2::Client.new(
          host: @config[:host],
          port: @config[:port] || DEFAULT_PORT,
          username: @config[:username],
          password: @config[:password] || "",
          database: "information_schema"
        )
      end
    end
  end
end

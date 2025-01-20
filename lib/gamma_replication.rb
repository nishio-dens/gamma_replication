# frozen_string_literal: true

require "active_support/all"
require "yaml"
require_relative "gamma_replication/version"
require_relative "gamma_replication/database_settings"
require_relative "gamma_replication/hook"
require_relative "gamma_replication/table"
require_relative "gamma_replication/database_connector"
require_relative "gamma_replication/database_connector/mysql_connector"
require_relative "gamma_replication/command"
require_relative "gamma_replication/command/base_replication"
require_relative "gamma_replication/command/start"
require_relative "gamma_replication/command/dryrun"
require_relative "gamma_replication/parser/data_parser"
require_relative "gamma_replication/maxwell_client"

module GammaReplication
  class Error < StandardError; end
end

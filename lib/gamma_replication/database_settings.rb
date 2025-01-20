# frozen_string_literal: true

module GammaReplication
  class DatabaseSettings
    attr_reader :settings, :in_database, :out_database

    def initialize(yaml_path)
      @settings = YAML.safe_load_file(yaml_path, permitted_classes: [Symbol, Hash],
                                                 symbolize_names: true).with_indifferent_access
      @in_database = @settings[:in_database_config]
      @out_database = @settings[:out_database_config]
    end

    def in_database_config
      @in_database
    end

    def out_database_config
      @out_database
    end
  end
end

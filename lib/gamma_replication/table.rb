# frozen_string_literal: true

module GammaReplication
  class Table
    DEFAULT_PRIMARY_KEY = "id"

    attr_accessor :table_name, :hooks,
                  :in_exist, :out_exist, :in_exist_columns, :out_exist_columns

    def initialize
      @hooks = []
      @in_exist_columns = []
      @out_exist_columns = []
    end

    def record_value(record)
      result = record.dup
      hooks.each do |hook|
        result = hook.execute_script(result)
      end
      result
    end

    def primary_key
      DEFAULT_PRIMARY_KEY
    end
  end
end

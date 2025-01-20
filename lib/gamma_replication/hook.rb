# frozen_string_literal: true

module GammaReplication
  class Hook
    attr_accessor :hook_type, :column_name, :script_path, :root_dir, :apply

    def execute_script(record)
      validate_script_exists
      result = record.dup
      load_script_file
      execute_hook(result)
    end

    private

    def validate_script_exists
      path = script_file_path
      raise "Hook Scripts Not Found. path: #{path}" unless File.exist?(path)
    end

    def script_file_path
      File.join(root_dir, script_path)
    end

    def load_script_file
      load script_file_path
    end

    def execute_hook(record)
      instance = create_hook_instance
      process_hook(instance, record)
    rescue StandardError
      raise "Invalid Hook Class #{hook_class_name}"
    end

    def create_hook_instance
      hook_class_name.constantize.new
    end

    def hook_class_name
      File.basename(script_file_path, ".*").camelize
    end

    def process_hook(instance, record)
      case hook_type.to_s
      when "column"
        process_column_hook(instance, record)
      when "row"
        process_row_hook(instance, record)
      else
        raise "Invalid hook type: #{hook_type}"
      end
    end

    def process_column_hook(instance, record)
      column = column_name.to_s
      record[column] = instance.execute(apply, column, record[column])
      record
    end

    def process_row_hook(instance, record)
      instance.execute(apply, record)
    end
  end
end

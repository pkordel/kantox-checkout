# frozen_string_literal: true

require "yaml"

class Config
  class << self
    def load(file_path)
      return [] unless File.exist?(file_path)

      begin
        data = YAML.safe_load_file(file_path)
      rescue Psych::SyntaxError => e
        raise "Failed to parse YAML file: #{e.message}"
      end

      validate_structure(data)

      # Return just the rules array, filtering active ones
      data["rules"].select { |rule| rule["active"] }
    end

    private

    def validate_structure(data)
      return if data.is_a?(Hash) && data["rules"].is_a?(Array)

      raise "Invalid configuration format: expected 'rules' array"
    end
  end
end

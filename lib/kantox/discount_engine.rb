# frozen_string_literal: true

require_relative "config"
require_relative "discount_rule_factory"

module Kantox
  class DiscountEngine
    attr_reader :rules

    def initialize(conf:)
      config_data = Config.load(conf)
      @rules = DiscountRuleFactory.create_rules(config_data)
    end
  end
end

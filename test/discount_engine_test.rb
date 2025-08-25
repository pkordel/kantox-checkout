# frozen_string_literal: true

require_relative "test_helper"

module Kantox
  class DiscountEngineTest < Minitest::Test
    def setup
      @discount_engine = DiscountEngine.new(conf: "./config/discounts.yml")
      @rules = @discount_engine.rules
    end

    def test_rules_loading
      assert_instance_of Array, @rules
      assert(@rules.all? { |rule| rule.is_a?(DiscountRule) })
      assert_equal 3, @rules.size
    end
  end
end

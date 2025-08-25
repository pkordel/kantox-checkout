# frozen_string_literal: true

require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!

require_relative "./discount_engine"

class DiscountEngineTest < Minitest::Test
  def setup
    @discount_engine = DiscountEngine.new(conf: "discounts.yml")
    @rules = @discount_engine.rules
  end

  def test_rules_loading
    assert_instance_of Array, @rules
    assert(@rules.all? { |rule| rule.is_a?(DiscountRule) })
    assert_equal 3, @rules.size
  end
end

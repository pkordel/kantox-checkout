require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!

require_relative "./discount_engine.rb"

class DiscountEngineTest < Minitest::Test
  def setup
    @discount_engine = DiscountEngine.new(conf: "discounts.yml")
  end

  def test_rules_loading
    assert_instance_of Array, @discount_engine.rules
    assert @discount_engine.rules.all? { |rule| rule.is_a?(DiscountRule) }
    assert_equal 3, @discount_engine.rules.size
  end
end
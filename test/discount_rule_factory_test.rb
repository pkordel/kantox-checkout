# frozen_string_literal: true

require_relative "test_helper"

module Kantox
  class DiscountRuleFactoryTest < Minitest::Test
    # rubocop:disable Metrics/MethodLength
    def test_rules_loading_with_valid_config
      data = Config.load("./test/fixtures/valid_discounts.yml")
      rules = DiscountRuleFactory.create_rules(data)
      assert_instance_of Array, rules
      assert(rules.all? { |rule| rule.is_a?(DiscountRule) })
      assert_equal 3, rules.size
    end

    def test_unknown_type
      data = [
        { "type" => "TYPE" }
      ]
      expected_message = "Unknown rule type: TYPE"
      assert_raises(RuntimeError, message: expected_message) do
        DiscountRuleFactory.create_rules(data)
      end
    end

    # Buy one get one free
    def test_valid_bogo_rule
      data = [
        {
          "type" => "buy_one_get_one_free",
          "sku" => "SKU",
          "active" => true
        }
      ]
      rules = DiscountRuleFactory.create_rules(data)
      assert_equal 1, rules.size
      rule = rules.first
      assert rule.is_a?(DiscountRule)
      assert_equal "SKU", rule.sku
    end

    def test_invalid_bogo_rule_missing_sku
      data = [
        {
          "type" => "buy_one_get_one_free",
          "active" => true
        }
      ]
      expected_message = "Invalid rule configuration: {sku: ['must be filled']}"
      assert_raises(RuntimeError, message: expected_message) do
        DiscountRuleFactory.create_rules(data)
      end
    end

    def test_invalid_bogo_rule_missing_active
      data = [
        {
          "type" => "buy_one_get_one_free",
          "sku" => "SKU"
        }
      ]
      expected_message = "Invalid rule configuration: {active: ['must be filled']}"
      assert_raises(RuntimeError, message: expected_message) do
        DiscountRuleFactory.create_rules(data)
      end
    end

    def test_invalid_bogo_rule_wrong_type_active
      data = [
        {
          "type" => "buy_one_get_one_free",
          "sku" => "SKU",
          "active" => "wrong"
        }
      ]
      expected_message = "Invalid rule configuration: {active: ['must be filled']}"
      assert_raises(RuntimeError, message: expected_message) do
        DiscountRuleFactory.create_rules(data)
      end
    end

    # Volume fixed price discount
    def test_valid_volume_fixed_price_rule
      data = [
        {
          "type" => "volume_fixed_price_discount",
          "sku" => "SKU",
          "active" => true,
          "minimum_quantity" => 2,
          "fixed_price" => 150
        }
      ]
      rules = DiscountRuleFactory.create_rules(data)
      assert_equal 1, rules.size
      rule = rules.first
      assert rule.is_a?(DiscountRule)
      assert_equal "SKU", rule.sku
    end

    def test_invalid_fixed_price_missing_minimum_quantity
      data = [
        {
          "type" => "volume_fixed_price_discount",
          "sku" => "SKU",
          "active" => true,
          "fixed_price" => 150
        }
      ]
      expected_message = "Invalid rule configuration: {minimum_quantity: ['must be filled']}"
      assert_raises(RuntimeError, message: expected_message) do
        DiscountRuleFactory.create_rules(data)
      end
    end

    def test_invalid_fixed_price_invalid_price_type
      data = [
        {
          "type" => "volume_fixed_price_discount",
          "sku" => "SKU",
          "active" => true,
          "minimum_quantity" => 2,
          "fixed_price" => "invalid"
        }
      ]
      expected_message = "Invalid rule configuration: {fixed_price: ['must be filled']}"
      assert_raises(RuntimeError, message: expected_message) do
        DiscountRuleFactory.create_rules(data)
      end
    end

    def test_invalid_fixed_price_invalid_price_negative
      data = [
        {
          "type" => "volume_fixed_price_discount",
          "sku" => "SKU",
          "active" => true,
          "minimum_quantity" => 2,
          "fixed_price" => -150
        }
      ]
      expected_message = "Invalid rule configuration: {fixed_price: ['must be filled']}"
      assert_raises(RuntimeError, message: expected_message) do
        DiscountRuleFactory.create_rules(data)
      end
    end

    # Volume fractional discount
    def test_valid_volume_fractional_discount_rule
      data = [
        {
          "type" => "volume_fractional_discount",
          "sku" => "SKU",
          "active" => true,
          "minimum_quantity" => 2,
          "fraction" => "2/3"
        }
      ]
      rules = DiscountRuleFactory.create_rules(data)
      assert_equal 1, rules.size
      rule = rules.first
      assert rule.is_a?(DiscountRule)
      assert_equal "SKU", rule.sku
    end

    def test_invalid_volume_fractional_rule_missing_fraction
      data = [
        {
          "type" => "volume_fractional_discount",
          "sku" => "SKU",
          "active" => true,
          "minimum_quantity" => 2
        }
      ]
      expected_message = "Invalid rule configuration: {fraction: ['is missing']}"
      assert_raises(RuntimeError, message: expected_message) do
        DiscountRuleFactory.create_rules(data)
      end
    end

    def test_invalid_volume_fractional_rule_invalid_fraction
      data = [
        {
          "type" => "volume_fractional_discount",
          "sku" => "SKU",
          "active" => true,
          "minimum_quantity" => 2,
          "fraction" => "invalid"
        }
      ]
      expected_message = "Invalid rule configuration: {fraction: ['must be a valid fraction (e.g., \"2/3\")']}"
      assert_raises(RuntimeError, message: expected_message) do
        DiscountRuleFactory.create_rules(data)
      end
    end
    # rubocop:enable Metrics/MethodLength
  end
end

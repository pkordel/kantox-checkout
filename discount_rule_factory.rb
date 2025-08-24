# frozen_string_literal: true

class DiscountRule
  attr_reader :sku

  def initialize(sku:)
    @sku = sku
  end

  def discount_cents(item:)
    raise NotImplementedError, "Subclasses must implement the discount_cents method"
  end
end

class BuyOneGetOneFreeDiscount < DiscountRule
  def discount_cents(item:)
    return 0 unless item.sku == sku

    free_units = item.quantity / 2
    free_units * item.price
  end
end

class VolumeFixedPriceDiscount < DiscountRule
  attr_reader :fixed_price, :minimum_quantity

  def initialize(sku:, fixed_price:, minimum_quantity:)
    super(sku: sku)
    @fixed_price      = fixed_price
    @minimum_quantity = minimum_quantity
  end

  def discount_cents(item:)
    return 0 unless item.sku == sku && item.quantity >= minimum_quantity

    original_total = item.price * item.quantity
    fixed_total    = fixed_price * item.quantity

    [original_total - fixed_total, 0].max
  end
end

class VolumeFractionDiscount < DiscountRule
  attr_reader :fraction, :minimum_quantity

  def initialize(sku:, fraction:, minimum_quantity:)
    super(sku: sku)
    @fraction         = fraction
    @minimum_quantity = minimum_quantity
  end

  def discount_cents(item:)
    return 0 unless item.sku == sku && item.quantity >= minimum_quantity

    original_total   = item.price * item.quantity
    discounted_unit  = (item.price * fraction)
    discounted_total = discounted_unit * item.quantity

    [original_total - discounted_total, 0].max
  end
end

require "dry-validation"
class DiscountRuleFactory
  # Base schema for all rules
  BaseRuleSchema = Dry::Validation.Contract do
    params do
      required(:type).filled(:string)
      required(:sku).filled(:string)
      required(:active).filled(:bool)
      optional(:id).filled(:string)
    end
  end

  # Schema for BOGO rules
  BogoRuleSchema = Dry::Validation.Contract do
    params do
      required(:type).value(eql?: 'buy_one_get_one_free')
      required(:sku).filled(:string)
      required(:active).filled(:bool)
      optional(:id).filled(:string)
    end
  end

  # Schema for volume fixed price rules
  VolumeFixedRuleSchema = Dry::Validation.Contract do
    params do
      required(:type).value(eql?: 'volume_fixed_price')
      required(:sku).filled(:string)
      required(:active).filled(:bool)
      required(:minimum_quantity).filled(:integer, gt?: 0)
      required(:fixed_price).filled(:integer, gt?: 0)
      optional(:id).filled(:string)
    end
  end

  # Schema for fractional rules
  FractionalRuleSchema = Dry::Validation.Contract do
    params do
      required(:type).value(eql?: 'fractional_percentage')
      required(:sku).filled(:string)
      required(:active).filled(:bool)
      required(:minimum_quantity).filled(:integer, gt?: 0)
      required(:fraction).filled(:string)
      optional(:id).filled(:string)
    end

    rule(:fraction) do
      Rational(value)
    rescue ArgumentError
      key.failure('must be a valid fraction (e.g., "2/3")')
    end
  end

  class << self
    def create_rules(config_data)
      config_data.map do |rule|
        validated_rule = validate_rule(rule)
        create_rule_object(validated_rule)
      end.compact
    end

    private

    def validate_rule(rule_data)
      case rule_data["type"]
      when "buy_one_get_one_free"
        result = BogoRuleSchema.call(rule_data)
      when "volume_fixed_price"
        result = VolumeFixedRuleSchema.call(rule_data)
      when "fractional_percentage"
        result = FractionalRuleSchema.call(rule_data)
      else
        raise "Unknown rule type: #{rule_data['type']}"
      end

      raise "Invalid rule configuration: #{result.errors.to_h}" if result.failure?

      result.to_h
    end

    def create_rule_object(rule)
      case rule[:type]
      when "buy_one_get_one_free"
        BuyOneGetOneFreeDiscount.new(sku: rule[:sku])
      when "fractional_percentage"
        VolumeFractionDiscount.new(
          sku: rule[:sku],
          minimum_quantity: rule[:minimum_quantity],
          fraction: Rational(rule[:fraction])
        )
      when "volume_fixed_price"
        VolumeFixedPriceDiscount.new(
          sku: rule[:sku],
          minimum_quantity: rule[:minimum_quantity],
          fixed_price: rule[:fixed_price]
        )
      end
    end
  end
end

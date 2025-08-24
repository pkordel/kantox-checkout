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

class DiscountRuleFactory
  def self.create_rules(config_data)
    config_data.map do |rule|
      case rule["type"]
      when "buy_one_get_one_free"
        BuyOneGetOneFreeDiscount.new(
          sku: rule["sku"]
        )
      when "fractional_percentage"
        VolumeFractionDiscount.new(
          sku: rule["sku"],
          minimum_quantity: rule["minimum_quantity"],
          fraction: Rational(rule["fraction"])
        )
      when "volume_fixed_price"
        VolumeFixedPriceDiscount.new(
          sku: rule["sku"],
          minimum_quantity: rule["minimum_quantity"],
          fixed_price: rule["fixed_price"]
        )
      end
    end.compact
  end
end

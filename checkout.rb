module Money
  module_function
  def fmt(cents) = format("£%.2f", cents.to_i / 100.0)
end

Product  = Struct.new(:sku, :name, :price)
LineItem = Struct.new(:sku, :name, :price, :quantity)
Order    = Struct.new(:items, :subtotal, :discount, :total, keyword_init: true) do
  require "terminal-table"
  def print_receipt
    table = Terminal::Table.new do |t|
      t.headings = ["Item", "Price", "Quantity"]
      items.each do |item|
        t.add_row([item.name, Money.fmt(item.price), item.quantity])
      end
      t.add_separator
      t.add_row(["Subtotal", Money.fmt(subtotal), ""])
      t.add_row(["Discount", Money.fmt(discount), ""])
      t.add_row(["Total",    Money.fmt(total), ""])
      t.align_column(1, :right)
      t.align_column(2, :right)
    end
    table.to_s
  end
end

class BuyOneGetOneFreeDiscount
  attr_reader :sku

  def initialize(sku:)
    @sku = sku
  end

  def discount_cents(item)
    return 0 unless item.sku == sku

    free_units = item.quantity / 2
    free_units * item.price
  end
end

class VolumeFixedPriceDiscount
  attr_reader :sku, :fixed_price, :minimum_quantity

  def initialize(sku:, fixed_price:, minimum_quantity:)
    @sku              = sku
    @fixed_price      = fixed_price
    @minimum_quantity = minimum_quantity
  end

  def discount_cents(item)
    return 0 unless item.sku == sku && item.quantity >= minimum_quantity

    original_total = item.price * item.quantity
    fixed_total    = fixed_price * item.quantity

    [original_total - fixed_total, 0].max
  end
end

class VolumePercentageDiscount
  attr_reader :sku, :minimum_quantity

  def initialize(sku:, minimum_quantity:)
    @sku              = sku
    @minimum_quantity = minimum_quantity
  end

  def discount_cents(item)
    return 0 unless item.sku == sku && item.quantity >= minimum_quantity

    original_total   = item.price * item.quantity
    discounted_unit  = ((item.price * 2.0) / 3.0)
    discounted_total = discounted_unit * item.quantity

    [original_total - discounted_total, 0].max
  end
end

class Basket
  attr_accessor :items

  def initialize
    @items = []
  end

  def add(item) = items << item

  def find_item(sku) = items.find { |item| item.sku == sku }

  def total_price_cents = items.sum { |item| item.price * item.quantity }
end

class Checkout
  attr_reader :pricing_rules, :basket

  def initialize(pricing_rules)
    @pricing_rules = pricing_rules
    @basket = Basket.new
  end

  def scan(item)
    if (existing_item = basket.find_item(item.sku))
      existing_item.quantity += 1
    else
      basket.add(LineItem.new(item.sku, item.name, item.price, 1))
    end
  end
  
  def total = subtotal - discount_cents

  def subtotal = basket.total_price_cents

  def discount_cents
    basket.items.sum do |item|
      pricing_rules.sum { |rule| rule.discount_cents(item) }
    end
  end

  def finalize_order
    order = Order.new(
      items:    basket.items,
      subtotal: subtotal,
      discount: discount_cents,
      total:    total
    )
    order.print_receipt
  end
end

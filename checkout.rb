module Money
  module_function
  def fmt(cents, currency_symbol: "£") = format("#{currency_symbol}%.2f", cents.to_i / 100.0)
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

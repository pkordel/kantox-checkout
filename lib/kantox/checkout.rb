# frozen_string_literal: true

module Kantox
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
        pricing_rules.sum { |rule| rule.discount_cents(item: item) }
      end
    end

    def finalize_order
      order = Order.new(
        items: basket.items,
        subtotal: subtotal,
        discount: discount_cents,
        total: total
      )
      order.print_receipt
    end
  end
end

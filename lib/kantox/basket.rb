# frozen_string_literal: true

module Kantox
  class Basket
    attr_reader :items

    def initialize
      @items = []
    end

    def add(item) = items << item

    def find_item(sku) = items.find { |item| item.sku == sku }

    def total_price_cents = items.sum { |item| item.price * item.quantity }
  end
end

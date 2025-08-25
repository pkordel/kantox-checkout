# frozen_string_literal: true

module Kantox
  Order = Struct.new(:items, :subtotal, :discount, :total, keyword_init: true) do
    require "terminal-table"
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def print_receipt
      table = Terminal::Table.new do |t|
        t.headings = %w[Item Price Quantity]
        items.each do |item|
          t.add_row([item.name, Money.fmt(cents: item.price), item.quantity])
        end
        t.add_separator
        t.add_row(["Subtotal", Money.fmt(cents: subtotal), ""])
        t.add_row(["Discount", Money.fmt(cents: discount), ""])
        t.add_row(["Total",    Money.fmt(cents: total), ""])
        t.align_column(1, :right)
        t.align_column(2, :right)
      end
      table.to_s
    end
    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
  end
end

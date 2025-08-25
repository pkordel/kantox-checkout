# frozen_string_literal: true

module Kantox
  class Money
    def self.fmt(cents: 0, currency_symbol: "£")
      format("#{currency_symbol}%.2f", cents.to_i / 100.0)
    end
  end
end

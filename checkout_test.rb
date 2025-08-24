require "minitest/autorun"
require "minitest/reporters"
Minitest::Reporters.use!

require_relative "./checkout.rb"
require_relative "./discount_engine.rb"

class CheckoutTest < Minitest::Test
  def setup
    discount_engine = DiscountEngine.new(conf: "discounts.yml")
    @checkout     = Checkout.new(discount_engine.rules)
    @green_tea    = Product.new("GR1", "Green Tea", 311)
    @strawberries = Product.new("SR1", "Strawberries", 500)
    @coffee       = Product.new("CF1", "Coffee", 1123)
  end

  def test_scanning_one_item
    @checkout.scan(@green_tea)
    assert_equal "£3.11", Money.fmt(@checkout.total)
  end

  def test_scanning_two_items_no_discount
    @checkout.scan(@strawberries)
    @checkout.scan(@strawberries)

    assert_equal "£10.00", Money.fmt(@checkout.total)
    assert_equal 1, @checkout.basket.items.count
  end

  def test_scanning_three_items_percentage_discount
    @checkout.scan(@coffee)
    @checkout.scan(@coffee)
    @checkout.scan(@coffee)

    assert_equal "£33.69", Money.fmt(@checkout.subtotal)
    assert_equal "£11.23", Money.fmt(@checkout.discount_cents)
    assert_equal "£22.46", Money.fmt(@checkout.total)
  end

  # GR1,SR1,GR1,GR1,CF1
  def test_scanning_multiple_items_bogo
    @checkout.scan(@green_tea)
    @checkout.scan(@strawberries)
    @checkout.scan(@green_tea)
    @checkout.scan(@green_tea)
    @checkout.scan(@coffee)

    assert_equal "£25.56", Money.fmt(@checkout.subtotal)
    assert_equal "£3.11",  Money.fmt(@checkout.discount_cents)
    assert_equal "£22.45", Money.fmt(@checkout.total)
  
    assert_equal 3, @checkout.basket.items.count

    # Finalize the order and print the receipt
    puts @checkout.finalize_order
  end

  # GR1,GR1
  def test_scanning_get_one_free
    @checkout.scan(@green_tea)
    @checkout.scan(@green_tea)

    assert_equal "£6.22", Money.fmt(@checkout.subtotal)
    assert_equal "£3.11", Money.fmt(@checkout.discount_cents)
    assert_equal "£3.11", Money.fmt(@checkout.total)
  end

  # SR1,SR1,GR1,SR1
  def test_scanning_fixed_price_discount
    @checkout.scan(@strawberries)
    @checkout.scan(@strawberries)
    @checkout.scan(@green_tea)
    @checkout.scan(@strawberries)

    assert_equal "£18.11", Money.fmt(@checkout.subtotal)
    assert_equal "£1.50", Money.fmt(@checkout.discount_cents)
    assert_equal "£16.61", Money.fmt(@checkout.total)
  end

  # GR1,CF1,SR1,CF1,CF1
  def test_scanning_percentage_discount
    @checkout.scan(@green_tea)
    @checkout.scan(@coffee)
    @checkout.scan(@strawberries)
    @checkout.scan(@coffee)
    @checkout.scan(@coffee)

    assert_equal "£41.80", Money.fmt(@checkout.subtotal)
    assert_equal "£11.23", Money.fmt(@checkout.discount_cents)
    assert_equal "£30.57", Money.fmt(@checkout.total)
  end

  def test_receipt_formatting
    @checkout.scan(@green_tea)
    @checkout.scan(@green_tea)
    @checkout.scan(@strawberries)
    @checkout.scan(@coffee)

    expected = <<~TABLE
      +--------------+--------+----------+
      | Item         | Price  | Quantity |
      +--------------+--------+----------+
      | Green Tea    |  £3.11 |        2 |
      | Strawberries |  £5.00 |        1 |
      | Coffee       | £11.23 |        1 |
      +--------------+--------+----------+
      | Subtotal     | £22.45 |          |
      | Discount     |  £3.11 |          |
      | Total        | £19.34 |          |
      +--------------+--------+----------+
    TABLE

    assert_equal expected.strip, @checkout.finalize_order
  end
end

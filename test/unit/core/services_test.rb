require "test_helper"

class Colppy::Core::ServicesTest < Minitest::Test

  def setup
    @services = Colppy::Core::SERVICES
  end

  def test_defined_services
    assert_equal [:company, :customer, :product, :sell_invoice, :user], @services.keys
  end

  def test_company_operations
    operations = @services[:company].keys

    assert_equal [:list, :read], operations
  end

  def test_customer_operations
    operations = @services[:customer].keys

    assert_equal [:list, :read, :create, :update], operations
  end

  def test_product_operations
    operations = @services[:product].keys

    assert_equal [:list, :create, :update], operations
  end

  def test_sell_invoice_operations
    operations = @services[:sell_invoice].keys

    assert_equal [:list, :read, :create], operations
  end

  def test_user_operations
    operations = @services[:user].keys

    assert_equal [:sign_in, :sign_out], operations
  end
end

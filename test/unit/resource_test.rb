require "test_helper"

class Colppy::ResourceTest < Minitest::Test

  def test_valid_invoices_types
    assert_equal %w(A B C E Z I M X), Colppy::Resource::VALID_INVOICE_TYPES
  end

end

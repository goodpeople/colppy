require "test_helper"

class Colppy::Core::GatewayTest < Minitest::Test

  def test_constants_present
    assert_instance_of String, Colppy::Core::Gateway::MIME_JSON
    assert_instance_of String, Colppy::Core::Gateway::SANDBOX_API_URL
    assert_instance_of String, Colppy::Core::Gateway::PRODUCTION_API_URL
    assert_instance_of String, Colppy::Core::Gateway::API_PATH
  end

  def test_sandbox_by_default
    @gateway = Colppy::Core::Gateway.new

    assert_equal true, @gateway.sandbox?
  end

  def test_live_initialize
    @gateway = Colppy::Core::Gateway.new("live")

    assert_equal false, @gateway.sandbox?
    assert_equal Colppy::Core::Gateway::PRODUCTION_API_URL, @gateway.send(:endpoint_url)
  end

  def test_live_initialize_change_to_sandbox
    @gateway = Colppy::Core::Gateway.new("live")
    @gateway.sandbox

    assert_equal true, @gateway.sandbox?
    assert_equal Colppy::Core::Gateway::SANDBOX_API_URL, @gateway.send(:endpoint_url)
  end

  def test_respond_to_call
    @gateway = Colppy::Core::Gateway.new

    assert_respond_to @gateway, :call
  end

end

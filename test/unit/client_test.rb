require "test_helper"

class Colppy::ClientTest < Minitest::Test

  def test_services_manifest
    assert_instance_of Hash, Colppy::Client::SERVICES_MANIFEST
  end

end

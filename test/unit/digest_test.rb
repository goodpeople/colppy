require "test_helper"

class Colppy::DigestTest < Minitest::Test

  def setup
    @digest = Colppy::Digest
  end

  def test_md5_digest_instance
    instance = @digest::MD5_DIGEST

    assert_instance_of OpenSSL::Digest, instance
    assert_equal "MD5", instance.name
  end

  def test_convert_strings_to_md5_hash
    string = "valid_string"
    string_hash = "e91ae2ea57df2d738d80b7020c0eb868"

    assert_equal string_hash, @digest.md5(string)
  end

  def test_do_nothing_with_a_valid_md5_hash
    string_hash = "e91ae2ea57df2d738d80b7020c0eb868"

    assert_equal string_hash, @digest.md5(string_hash)
  end

end

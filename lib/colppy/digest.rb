module Colppy
  module Digest
    module_function

    MD5_DIGEST = OpenSSL::Digest.new("md5").freeze

    def md5(string)
      return string if valid_md5?(string)
      MD5_DIGEST.hexdigest(string)
    end

    def valid_md5?(string)
      !!(%r{^[a-f0-9]{32}$}i =~ string)
    end
  end
end

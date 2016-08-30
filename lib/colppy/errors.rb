module Colppy
  class Error < StandardError; end
  class ClientError < Error; end
  class DataError < Error; end
  class ResourceError < Error; end
  class ServiceError < Error; end
end

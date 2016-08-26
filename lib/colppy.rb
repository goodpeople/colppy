# SUPPORT LIBS
require 'faraday'
require 'multi_json'

require "colppy/version"
require "colppy/digest"
require "colppy/utils"
# CORE
require "colppy/core/services"
require "colppy/core/gateway"
# RESOURCES
require "colppy/resource"
require "colppy/resources/customer"
require "colppy/resources/company"
require "colppy/resources/user"
# CLIENT
require "colppy/errors"
require "colppy/client"

module Colppy
end

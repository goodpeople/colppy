module Colppy
  module CompanyActions
    extend self

    def companies
      @companies ||= Company.all(self)
    end

  end

  class Company < Resource
    attr_reader :id, :name

    class << self
      def all(client)
        list(client)
      end

      def list(client, parameters = {})
        response = client.call(
          :company,
          :list,
          parameters.merge(client.session_params)
        )
        if response[:success]
          response[:data].map do |params|
            new(params.merge(client: client))
          end
        else
          response
        end
      end
    end

    def initialize(client: nil, **params)
      @client = client if client && client.is_a?(Colppy::Client)
      @id = params.delete(:IdEmpresa)
      @name = params.delete(:razonSocial)
      @extras = params
    end

    def customers
      ensure_client_valid!

      Customer.all(@client, self)
    end

    def params
      { idEmpresa: @id }
    end

    private

    def attr_inspect
      [:id, :name]
    end

    def ensure_client_valid!
      unless @client && @client.is_a?(Colppy::Client)
        raise ResourceError.new(
          "You should provide a client, and it should be a Colppy::Client instance"
        )
      end
    end
  end
end

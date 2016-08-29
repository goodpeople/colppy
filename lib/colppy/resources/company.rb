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
          results = response[:data].map do |params|
            new(params.merge(client: client))
          end
          parse_list_response(results, response[:total].to_i, parameters)
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

    def customers(params = {})
      ensure_client_valid!
      if params.empty?
        Customer.all(@client, self)
      else
        Customer.list(@client, self, params)
      end
    end

    def customer(id)
      ensure_client_valid!

      Customer.get(@client, self, id)
    end

    def params
      { idEmpresa: @id }
    end

    private

    def attr_inspect
      [:id, :name]
    end

  end
end

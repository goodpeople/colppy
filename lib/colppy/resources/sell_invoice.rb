module Colppy
  class SellInvoice < Resource
    attr_reader :id, :number, :data

    class << self
      def all(client, company)
        list(client, company)
      end

      def list(client, company, parameters = {})
        call_parameters = base_params.merge(parameters)
        response = client.call(
          :sell_invoice,
          :list,
          extended_parameters(client, company, call_parameters)
        )
        if response[:success]
          results = response[:data].map do |params|
            new(params.merge(client: client, company: company))
          end
          parse_list_response(results, response[:total].to_i, call_parameters)
        else
          response
        end
      end

      private

      def extended_parameters(client, company, parameters)
        [ client.session_params,
          company.params,
          parameters
        ].inject(&:merge)
      end

      def base_params
        {
          filter:[],
          order: {
            field: ["nroFactura"],
            order: "desc"
          }
        }
      end

    end

    def initialize(client: nil, company: nil, **params)
      @client = client if client && client.is_a?(Colppy::Client)
      @company = company if company && company.is_a?(Colppy::Company)
      @id = params.delete(:idFactura)
      @number = params.delete(:nroFactura)
      @data = params
    end

    def new?
      id.nil? || id.empty?
    end

    def save
      ensure_client_valid! && ensure_company_valid!

      # response = @client.call(
      #   :sell_invoice,
      #   :create,
      #   save_parameters
      # )
      # if response[:success]
      #   @id = response[:data][:idFactura]
      #   self
      # else
        false
      # end
    end

    def []=(key, value)
      key_sym = key.to_sym
      if protected_data_keys.include?(key_sym)
        raise ResourceError.new("You cannot change any of this values: #{protected_data_keys.join(", ")} manually")
      end
      @data[key_sym] = value
    end

    private

    def attr_inspect
      [:id, :number]
    end

    def protected_data_keys
      [:idFactura, :idEmpresa, :nroFactura]
    end

    def save_parameters
      [
        @client.session_params,
        params
      ].inject(&:merge)
    end

    def params
      {

      }
    end
  end
end

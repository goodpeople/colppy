module Colppy
  module CompanyActions
    extend self

    def companies
      @companies ||= Company.all(self)
    end

  end

  class Company < Resource
    attr_reader :id, :name

    ATTRIBUTES_MAPPER = {
      idPlan: :plan_id,
      activa: :active,
      fechaVencimiento: :expiration_date
    }.freeze
    PROTECTED_DATA_KEYS = ATTRIBUTES_MAPPER.values

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

      @id = params.delete(:IdEmpresa) || params.delete(:id)
      @name = params.delete(:razonSocial) || params.delete(:name)
      super(params)
    end

    def customers(params = {})
      ensure_client_valid!

      if params.empty?
        Customer.all(@client, self)
      else
        Customer.list(@client, self, params)
      end
    end

    def customer_by_id(id)
      ensure_client_valid!

      Customer.get(@client, self, id)
    end

    def products(params = {})
      ensure_client_valid!

      if params.empty?
        Product.all(@client, self)
      else
        Product.list(@client, self, params)
      end
    end
    alias :customer :customer_by_id

    def product_by_code(code)
      ensure_client_valid!

      params = {
        filter: [
          { field: "codigo", op: "=", value: code }
        ]
      }
      response = Product.list(@client, self, params)
      response[:results].last
    end

    def product_by_id(id)
      ensure_client_valid!

      params = {
        filter: [
          { field: "idItem", op: "=", value: id }
        ]
      }
      response = Product.list(@client, self, params)
      response[:results].last
    end
    alias :product :product_by_id

    def sell_invoices(params = {})
      ensure_client_valid!

      if params.empty?
        SellInvoice.all(@client, self)
      else
        SellInvoice.list(@client, self, params)
      end
    end

    def sell_invoice_by_id(id)
      ensure_client_valid!

      SellInvoice.get(@client, self, id)
    end
    alias :sell_invoice :sell_invoice_by_id

    def params
      { idEmpresa: @id }
    end

    private

    def attr_inspect
      [:id, :name]
    end

  end
end

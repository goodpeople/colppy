module Colppy
  module CompanyActions
    extend self

    def companies
      return @companies if @companies
      _companies = Company.all(self)
      if _companies[:results]
        @companies = _companies[:results]
      else
        _companies
      end
    end

    def company_by_id(id)
      if @companies
        @companies.detect do |company|
          company.id == id
        end
      else
        Company.get(self, id)
      end
    end
    alias :company :company_by_id

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

      def get(client, id)
        response = client.call(
          :company,
          :read,
          client.session_params.merge({ idEmpresa: id })
        )
        if response[:success]
          new(response[:data].merge(client: client))
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
    alias :customer :customer_by_id

    def products(params = {})
      ensure_client_valid!

      if params.empty?
        Product.all(@client, self)
      else
        Product.list(@client, self, params)
      end
    end
    def product_by_code(code)
      ensure_client_valid!

      params = {
        filter: [
          { field: "codigo", op: "=", value: code }
        ]
      }

      response = Product.list(@client, self, params)

      response[:results].last if response.key?(:results)
    end

    def product_by_id(id)
      ensure_client_valid!

      params = {
        filter: [
          { field: "idItem", op: "=", value: id }
        ]
      }

      response = Product.list(@client, self, params)

      response[:results].last if response.key?(:results)
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

    def available_accounts
      return @available_accounts unless @available_accounts.nil? || @available_accounts.empty?

      response = @client.call(
        :inventory,
        :accounts_list,
        params.merge(@client.session_params)
      )
      if response[:success]
        @available_accounts = response[:cuentas].map do |account|
          {
            id: account[:Id],
            account_id: account[:idPlanCuenta],
            full_name: account[:Descripcion],
            name: account[:Descripcion].split(' - ')[1]
          }
        end
      end
    end
    def account_name(account_id)
      return if available_accounts.nil? || available_accounts.empty?

      if account = available_accounts.detect{ |a| a[:account_id].to_s == account_id.to_s }
        account[:name]
      end
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

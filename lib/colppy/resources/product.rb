module Colppy
  class Product < Resource
    attr_reader :id, :name, :code

    ATTRIBUTES_MAPPER = {
      idItem: :id,
      idEmpresa: :company_id,
      codigo: :code,
      descripcion: :name,
      detalle: :detail,
      precioVenta: :sell_price,
      ultimoPrecioCompra: :last_purchase_price,
      ctaInventario: :inventory_account,
      ctaCostoVentas: :sales_costs_account,
      ctaIngresoVentas: :sales_account,
      iva: :tax,
      tipoItem: :item_type,
      unidadMedida: :measure_unit,
      minimo: :minimum_stock,
      disponibilidad: :availability
    }.freeze
    PROTECTED_DATA_KEYS = [:id, :company_id, :name, :code].freeze
    DATA_KEYS_SETTERS = (ATTRIBUTES_MAPPER.values - PROTECTED_DATA_KEYS).freeze

    class << self
      def all(client, company)
        list(client, company)
      end

      def list(client, company, parameters = {})
        call_parameters = base_params.merge(parameters)
        response = client.call(
          :product,
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
          order: [{
            field: "codigo",
            dir: "asc"
          }]
        }
      end

    end

    def initialize(client: nil, company: nil, **params)
      @client = client if client && client.is_a?(Colppy::Client)
      @company = company if company && company.is_a?(Colppy::Company)

      @id = params.delete(:idItem) || params.delete(:id)
      @name = params.delete(:descripcion) || params.delete(:name)
      @code = params.delete(:codigo) || params.delete(:code)

      super(params)
    end
    DATA_KEYS_SETTERS.each do |data_key|
      define_method("#{data_key}") do
        @data[data_key.to_sym]
      end
      define_method("#{data_key}=") do |value|
        @data[data_key.to_sym] = value
      end
    end

    def new?
      @id.nil? || @id.empty?
    end

    def exist?
      !new?
    end

    def name=(value)
      @name = value
    end

    def code=(value)
      @code = value
    end

    def save
      ensure_client_valid! && ensure_company_valid!

      response = @client.call(
        :product,
        operation,
        save_parameters
      )
      if response[:success]
        response_data = response[:data]
        case operation
        when :create
          @id = response_data[:idItem]
        end
        self
      else
        false
      end
    end

    def sales_account
      check_mandatory_account!(:sales_account)
    end

    private

    def attr_inspect
      [:id, :code, :name]
    end

    def operation
      new? ? :create : :update
    end

    def save_parameters
      [
        @client.session_params,
        params
      ].inject(&:merge)
    end

    def params
      {
        idItem: @id || "",
        idEmpresa: @company.id,
        codigo: @code || "",
        descripcion: @name || "",
        detalle: @data[:detail] || "",
        precioVenta: @data[:sell_price] || "0",
        ultimoPrecioCompra: @data[:last_purchase_price] || "",
        ctaInventario: check_mandatory_account!(:inventory_account),
        ctaCostoVentas: check_mandatory_account!(:sales_costs_account),
        ctaIngresoVentas: check_mandatory_account!(:sales_account),
        iva: @data[:tax] || "21",
        tipoItem: @data[:item_type] || "P",
        unidadMedida: @data[:measure_unit] || "u",
        minimo: @data[:minimum_stock] || "0"
      }
    end

    def check_mandatory_account!(account)
      if account_name_or_id = @data[account]
        real_account_name = @company.account_name(account_name_or_id)
        if real_account_name
          real_account_name
        else
          account_name_or_id
        end
      else
        raise DataError.new("The :#{account} is required for the product. You should specify one via product.#{account} = '', or product[:#{account}] = '', or when you initialize it. You should check the available and valid accounts in Colppy")
      end
    end
  end
end

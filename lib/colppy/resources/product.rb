module Colppy
  class Product < Resource
    attr_reader :id, :name, :sku, :data

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
      @id = params.delete(:idItem)
      @name = params.delete(:descripcion)
      @sku = params.delete(:codigo)
      @data = params
    end

    def new?
      id.nil? || id.empty?
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

    def name=(new_name)
      @name = new_name
    end

    def sku=(new_sku)
      @sku = new_sku
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
      [:id, :sku, :name]
    end

    def protected_data_keys
      [:idItem, :idEmpresa]
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
        idItem: id || "",
        idEmpresa: @company.id,
        codigo: sku || "",
        descripcion: name || "",
        detalle: @data[:detalle] || "",
        minimo: @data[:minimo] || "0",
        precioVenta: @data[:precioVenta] || "0",
        ultimoPrecioCompra: @data[:minimo] || "0",
        ctaInventario: @data[:ctaInventario] || "",
        ctaCostoVentas: @data[:ctaCostoVentas] || "",
        ctaIngresoVentas: @data[:ctaIngresoVentas] || "",
        iva: @data[:iva] || "21",
        tipoItem: @data[:tipoItem] || "P",
        unidadMedida: @data[:unidadMedida] || "P",
        minimo: @data[:minimo] || "0"
      }
    end
  end
end

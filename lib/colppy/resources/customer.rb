module Colppy
  class Customer < Resource
    attr_reader :id, :name, :data

    class << self
      def all(client, company)
        list(client, company)
      end

      def list(client, company, parameters = {})
        call_parameters = base_params.merge(parameters)
        response = client.call(
          :customer,
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

      def get(client, company, id)
        response = client.call(
          :customer,
          :read,
          extended_parameters(client, company, { idCliente: id })
        )
        if response[:success]
          new(response[:data].merge(client: client, company: company))
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
            field: "RazonSocial",
            dir: "asc"
          }]
        }
      end

    end

    def initialize(client: nil, company: nil, **params)
      @client = client if client && client.is_a?(Colppy::Client)
      @company = company if company && company.is_a?(Colppy::Company)
      @id = params.delete(:idCliente)
      @name = params.delete(:RazonSocial)
      @data = params
    end

    def new?
      id.nil? || id.empty?
    end

    def save
      ensure_client_valid! && ensure_company_valid!
      binding.pry
      response = @client.call(
        :customer,
        operation,
        save_parameters
      )
      if response[:success]
        data = response[:data]
        case operation
        when :create
          @id = data[:idCliente]
        when :update
          @data[:NombreFantasia] = data[:nombreCliente]
        end
        self
      else
        false
      end
    end

    def name=(new_name)
      @name = new_name
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
      [:id, :name]
    end

    def protected_data_keys
      [:idUsuario, :idCliente, :idEmpresa]
    end

    def operation
      new? ? :create : :update
    end

    def save_parameters
      [
        @client.session_params,
        info_general: general_info_params,
        info_otra: other_info_params
      ].inject(&:merge)
    end

    def general_info_params
      {
        idUsuario: @client.username,
        idCliente: id || "",
        idEmpresa: @company.id,
        NombreFantasia: @data[:NombreFantasia] || "",
        RazonSocial: name || "",
        CUIT: @data[:CUIT] || "",
        DirPostal: @data[:DirPostal] || "",
        DirPostalCiudad: @data[:DirPostalCiudad] || "",
        DirPostalCodigoPostal: @data[:DirPostalCodigoPostal] || "",
        DirPostalProvincia: @data[:DirPostalProvincia] || "",
        DirPostalPais: @data[:DirPostalPais] || "Argentina",
        Telefono: @data[:Telefono] || "",
        Email: @data[:Email] || ""
      }
    end

    def other_info_params
      {
        Activo: @data[:Activo] || "1",
        FechaAlta: @data[:FechaAlta] || "",
        DirFiscal: @data[:DirFiscal] || "",
        DirFiscalCiudad: @data[:DirFiscalCiudad] || "",
        DirFiscalCodigoPostal: @data[:DirFiscalCodigoPostal] || "",
        DirFiscalProvincia: @data[:DirFiscalProvincia] || "",
        DirFiscalPais: @data[:DirFiscalPais] || "",
        idCondicionPago: @data[:idCondicionPago] || "",
        idCondicionIva: @data[:idCondicionIva] || "",
        porcentajeIVA: @data[:porcentajeIVA] || "",
        idPlanCuenta: @data[:idPlanCuenta] || "",
        CuentaCredito: @data[:CuentaCredito] || "",
        DirEnvio: @data[:DirEnvio] || "",
        DirEnvioCiudad: @data[:DirEnvioCiudad] || "",
        DirEnvioCodigoPostal: @data[:DirEnvioCodigoPostal] || "",
        DirEnvioProvincia: @data[:DirEnvioProvincia] || "",
        DirEnvioPais: @data[:DirEnvioPais] || ""
      }
    end
  end
end

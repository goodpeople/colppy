module Colppy
  class Customer < Resource
    attr_reader :id, :name

    ATTRIBUTES_MAPPER = {
      RazonSocial: :name,
      NombreFantasia: :fantasy_name,
      DirPostal: :address,
      DirPostalCiudad: :address_city,
      DirPostalCodigoPostal: :address_zipcode,
      DirPostalProvincia: :address_state,
      DirPostalPais: :address_country,
      DirFiscal: :legal_address,
      DirFiscalCiudad: :legal_address_city,
      DirFiscalCodigoPostal: :legal_address_zipcode,
      DirFiscalProvincia: :legal_address_state,
      DirFiscalPais: :legal_address_country,
      Telefono: :phone_number,
      Fax: :fax_number,
      Activo: :active,
      idCondicionPago: :payment_condition_id,
      idCondicionIva: :tax_condition_id,
      CUIT: :cuit,
      dni: :dni,
      idTipoPercepcion: :tax_perception_id,
      NroCuenta: :account_number,
      CBU: :cbu,
      Banco: :bank,
      porcentajeIVA: :tax,
      Email: :email,
      Saldo: :balance
    }.freeze
    PROTECTED_DATA_KEYS = [:id, :company_id, :name].freeze
    DATA_KEYS_SETTERS = (ATTRIBUTES_MAPPER.values - PROTECTED_DATA_KEYS).freeze

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

      @id = params.delete(:idCliente) || params.delete(:id)
      @name = params.delete(:RazonSocial) || params.delete(:name)
      super(params)
    end
    DATA_KEYS_SETTERS.each do |data_key|
      define_method("#{data_key}=") do |value|
        @data[data_key.to_sym] = value
      end
    end

    def new?
      id.nil? || id.empty?
    end

    def save
      ensure_client_valid! && ensure_company_valid!

      response = @client.call(
        :customer,
        operation,
        save_parameters
      )
      if response[:success]
        response_data = response[:data]
        case operation
        when :create
          @id = response_data[:idCliente]
        when :update
          @data[:NombreFantasia] = response_data[:nombreCliente]
        end
        self
      else
        false
      end
    end

    def name=(new_name)
      @name = new_name
    end

    private

    def attr_inspect
      [:id, :name]
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
        NombreFantasia: @data[:fantasy_name] || "",
        RazonSocial: @name || "",
        CUIT: @data[:cuit] || "",
        dni: @data[:dni] || "",
        DirPostal: @data[:address].truncate(59) || "",
        DirPostalCiudad: @data[:address_city] || "",
        DirPostalCodigoPostal: @data[:address_zipcode] || "",
        DirPostalProvincia: @data[:address_state] || "",
        DirPostalPais: @data[:address_country] || "Argentina",
        Telefono: @data[:phone_number] || "",
        Email: @data[:email] || ""
      }
    end

    def other_info_params
      {
        Activo: @data[:active] || "1",
        FechaAlta: @data[:FechaAlta] || "",
        DirFiscal: @data[:legal_address].truncate(59) || "",
        DirFiscalCiudad: @data[:legal_address_city] || "",
        DirFiscalCodigoPostal: @data[:legal_address_zipcode] || "",
        DirFiscalProvincia: @data[:legal_address_state] || "",
        DirFiscalPais: @data[:legal_address_country] || "Argentina",
        idCondicionPago: @data[:payment_condition_id] || "0",
        idCondicionIva: @data[:tax_condition_id] || "",
        porcentajeIVA: @data[:tax] || "21",
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

module Colppy
  class Customer < Resource
    attr_reader :id, :name

    class << self
      def all(client, company)
        list(client, company)
      end

      def list(client, company, parameters = {})
        response = client.call(
          :customer,
          :list,
          extended_parameters(client, company, parameters)
        )
        if response[:success]
          response[:data].map do |params|
            new(params.merge(client: client, company: company))
          end
        else
          response
        end
      end

      private

      def extended_parameters(client, company, parameters)
        [ base_params,
          client.session_params,
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
      @extras = params
    end

    private

    def attr_inspect
      [:id, :name]
    end

    def general_info_params
      {
        idUsuario: "",
        idCliente: "",
        idEmpresa: "",
        NombreFantasia: "",
        RazonSocial: "",
        CUIT: "",
        DirPostal: "",
        DirPostalCiudad: "",
        DirPostalCodigoPostal: "",
        DirPostalProvincia: "",
        DirPostalPais: "",
        Telefono: "",
        Email: ""
      }
    end

    def other_info_params
      {
        Activo: "1",
        FechaAlta: "",
        DirFiscal: "",
        DirFiscalCiudad: "",
        DirFiscalCodigoPostal: "",
        DirFiscalProvincia: "",
        DirFiscalPais: "",
        idCondicionPago: "",
        idCondicionIva: "",
        porcentajeIVA: "",
        idPlanCuenta: "",
        CuentaCredito: "",
        DirEnvio: "",
        DirEnvioCiudad: "",
        DirEnvioCodigoPostal: "",
        DirEnvioProvincia: "",
        DirEnvioPais: ""
      }
    end
  end
end

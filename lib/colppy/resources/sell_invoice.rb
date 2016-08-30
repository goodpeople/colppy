module Colppy
  class SellInvoice < Resource
    attr_reader :id, :number, :cae, :items, :data, :url
    attr_accessor :payments

    VALID_RECEIPT_TYPES = %w(4 6 8 NCV)

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

      def get(client, company, id)
        response = client.call(
          :sell_invoice,
          :read,
          extended_parameters(client, company, { idFactura: id })
        )
        if response[:success]
          new(extended_response(response, client, company))
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

      def extended_response(response, client, company)
        [ response[:infofactura],
          items: response[:itemsFactura],
          url: response[:UrlFacturaPdf],
          client: client,
          company: company
        ].inject(&:merge)
      end

    end

    def initialize(client: nil, company: nil, customer: nil, **params)
      @client = client if client && client.is_a?(Colppy::Client)
      @company = company if company && company.is_a?(Colppy::Company)
      @customer = customer if customer && customer.is_a?(Colppy::Customer)

      @id = params.delete(:idFactura)
      @number = params.delete(:nroFactura)
      @cae = params.delete(:cae)

      @items = parse_items(params.delete(:items))
      @payments = params.delete(:ItemsCobro) || []

      @data = params
      @url = build_pdf_url
    end

    def new?
      id.nil? || id.empty?
    end

    def editable?
      cae.nil? || cae.empty?
    end

    def save
      ensure_editability! && ensure_client_valid! && ensure_company_valid! && ensure_customer_valid!

      response = @client.call(
        :sell_invoice,
        :create,
        save_parameters
      )
      binding.pry
      if response[:success]
        @id = response[:data][:idFactura]
        self
      else
        false
      end
    end

    def []=(key, value)
      ensure_editability!

      key_sym = key.to_sym
      if protected_data_keys.include?(key_sym)
        raise ResourceError.new("You cannot change any of this values: #{protected_data_keys.join(", ")} manually")
      end
      @data[key_sym] = value
    end

    def items=(new_items)
      @charged_details = nil
      @items = parse_items(new_items)
    end

    private

    def attr_inspect
      [:id, :number, :cae]
    end

    def protected_data_keys
      [:idFactura, :idEmpresa, :nroFactura]
    end

    def parse_items(new_items)
      return [] if new_items.nil? || new_items.empty?

      new_items.map do |item|
        item.tap do |hash|
          if item[:idItem] && (item[:product].nil? || item[:product].empty?)
            item[:product] = @company.product(item[:idItem])
          end
        end
      end
    end

    def build_pdf_url
      return if data[:url].nil? || data[:url].empty?

      data[:url] = "#{data[:url]}?usuario=#{@client.username}&claveSesion=#{@client.session_key}&idEmpresa=#{@company.id}&idFactura=#{id}&idCliente=#{data[:idCliente]}"
    end

    def save_parameters
      [
        @client.session_params,
        general_params,
        invoice_payments_params,
        itemsFactura: invoice_items_params,
        totalesiva: total_taxes_params
      ].inject(&:merge)
    end

    def general_params
      {
        idCliente: @customer.id || @data[:idCliente] || "",
        idEmpresa: @company.id,
        descripcion: @data[:descripcion] || "",
        fechaFactura: valid_date(@data[:fechaFactura]),
        idCondicionPago: @data[:idCondicionPago] || "Contado",
        fechaPago: valid_date(@data[:fechaPago]),
        idEstadoAnterior: @data[:idEstadoAnterior] || "",
        idEstadoFactura: @data[:idEstadoFactura] || "Cobrada",
        idFactura: id || "",
        idMedioCobro: @data[:idMedioCobro] || "Efectivo",
        idMoneda: @data[:idMoneda] || "1",
        idTipoComprobante: receipt_type,
        idTipoFactura: invoice_type,
        netoGravado: (charged_details[:total_taxed] || 0.00).to_s,
        netoNoGravado: (charged_details[:total_non_taxed] || 0.00).to_s,
        nroFactura1: @data[:nroFactura1] || "0001",
        nroFactura2: @data[:nroFactura2] || "",
        percepcionIVA: (@data[:percepcionIVA] || 0.00).to_s,
        percepcionIIBB: (@data[:percepcionIIBB] || 0.00).to_s,
        totalFactura: (charged_details[:total] || 0.00).to_s,
        totalIVA: (charged_details[:tax_total] || 0.00).to_s,
        valorCambio: @data[:valorCambio] || "1",
      }.tap do |params|
        params[:labelfe] = "Factura Electrónica" if @data[:labelfe]
      end
    end

    def invoice_items_params
      items.map do |item|
        if item[:product] && item[:product].is_a?(Colppy::Product)
          product = item[:product]
          [
            product.params_for_invoice,
            item_params(item, false)
          ].inject(&:merge)
        elsif item.is_a?(Hash)
          item_params(item)
        end
      end
    end

    def item_params(item, fill_empty = true)
      {
        Cantidad: item[:Cantidad],
        porcDesc: item[:porcDesc] || "0.00"
      }.tap do |params|
        if value = item[:ImporteUnitario] || fill_empty
          params[:ImporteUnitario] = value || ""
        end
        if value = item[:idPlanCuenta] || fill_empty
          params[:idPlanCuenta] = value || ""
        end
        if value = item[:IVA] || fill_empty
          params[:IVA] = value || "21"
        end
        if value = item[:Comentario] || fill_empty
          params[:Comentario] = value || ""
        end
      end
    end

    def invoice_payments_params
      return {} unless payments
      payment_items = payments.map do |payment|
        {
          idMedioCobro: payment[:idMedioCobro] || "Efectivo",
          idPlanCuenta: payment[:idPlanCuenta] || "Caja en pesos",
          Banco: payment[:Banco] || "",
          nroCheque: payment[:nroCheque] || "",
          fechaValidez: payment[:fechaValidez] || "",
          importe: payment[:importe] || "0",
          VAD: payment[:VAD] || "S"
        }
      end
      { ItemsCobro: payment_items }
    end

    def total_taxes_params
      charged_details[:tax_details].map do |tax, values|
        {
          alicuotaIva: tax.to_s,
          baseImpIva: values[:total_taxed].to_s,
          importeIva: values[:tax_total].to_s
        }
      end
    end

    def charged_details
      return @charged_details unless @charged_details.nil? || @charged_details.empty?

      if items.nil? || items.empty?
        raise DataError.new("In order to save an SellInvoice you should at least have one item in it")
      else
        default_object = {
          total_taxed: 0.00,
          total_nontaxed: 0.00,
          total: 0.00,
          tax_total: 0.00,
          tax_details:{}
        }
        @charged_details = items.each_with_object(default_object) do |item, result|
          product_data = (item[:product] && item[:product].data) || {}
          iva = (item[:IVA] || product_data[:iva] || 0).to_f
          charged = (item[:ImporteUnitario] || product_data[:precioVenta] || 0).to_f
          quantity = (item[:Cantidad] || 0).to_i
          total = ( charged * quantity ).round(2)
          if iva > 0
            tax = (( total * iva ) / 100).round(2)
            result[:tax_total] += tax
            result[:total_taxed] += total - tax
            result[:tax_details][iva] = {
              tax_total: result[:tax_total],
              total_taxed: result[:total_taxed]
            }
          else
            result[:total_nontaxed] += total
          end
          result[:total] += total
        end
      end
    end

    def ensure_editability!
      unless editable?
        raise ResourceError.new("You cannot change any value of this invoice, because it's already processed by AFIP. You should create a new one instead")
      end
    end

    def invoice_status
      type = @data[:idEstadoFactura]
      if type && VALID_INVOICE_STATUS.include?(type)
        type
      else
        raise DataError.new("The value of idEstadoFactura:#{type} is invalid. The value should be any of this ones: #{VALID_INVOICE_STATUS.join(", ")}")
      end
    end

    def invoice_type
      type = @data[:idTipoFactura]
      if type && VALID_INVOICE_TYPES.include?(type)
        type
      else
        raise DataError.new("The idTipoFactura:#{type} is invalid. The value should be any of this ones: #{VALID_INVOICE_TYPES.join(", ")}")
      end
    end

    def receipt_type
      type = @data[:idTipoComprobante]
      if type && VALID_RECEIPT_TYPES.include?(type)
        type
      else
        raise DataError.new("The idTipoComprobante:#{type} is invalid. The value should be any of this ones: #{VALID_RECEIPT_TYPES.join(", ")}")
        ""
      end
    end
  end
end

# "totalesiva":[
#   {
#     alicuotaIva: "0",
#     baseImpIva: "0.00",
#     importeIva: "0.00"
#   },
  # {
  #   alicuotaIva: "21",
  #   baseImpIva: "101.65",
  #   importeIva: "21.35"
  # },
#   {
#     alicuotaIva: "27",
#     baseImpIva: "0.00",
#     importeIva: "0.00"
#   }
# ]

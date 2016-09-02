module Colppy
  class SellInvoice < Invoice
    attr_reader :id, :number, :cae, :url, :items

    VALID_RECEIPT_TYPES = %w(4 6 8 NCV)
    ATTRIBUTES_MAPPER = {
      descripcion: :description,
      fechaFactura: :invoice_date,
      idCondicionPago: :payment_condition_id, # validate
      fechaPago: :payment_date,
      idEmpresa: :company_id,
      idCliente: :customer_id,
      idEstadoAnterior: :previous_status_id, # validate
      idEstadoFactura: :status_id, # validate
      idMoneda: :currency_id,
      idTipoComprobante: :receipt_type_id, # validate
      idTipoFactura: :invoice_type_id, # validate
      idUsuario: :user_id,
      labelfe: :electronic_bill,
      netoGravado: :total_taxed,
      netoNoGravado: :total_nontaxed,
      nroFactura1: :invoice_number1,
      nroFactura2: :invoice_number2,
      percepcionIIBB: :iibb_perception,
      percepcionIVA: :tax_perception,
      tipoFactura: :invoice_type, # validate
      totalFactura: :total,
      totalIVA: :total_taxes,
      totalpagadofactura: :total_payed,
      valorCambio: :exchange_rate,
      nroRepeticion: :repetition_number,
      periodoRep: :repetition_period,
      nroVencimiento: :expiration_number,
      tipoVencimiento: :expiration_type,
      fechaFin: :end_date
    }.freeze
    PROTECTED_DATA_KEYS = [:id, :company_id, :customer_id, :number, :cae].freeze
    DATA_KEYS_SETTERS = (ATTRIBUTES_MAPPER.values - PROTECTED_DATA_KEYS).freeze

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
          itemsFactura: response[:itemsFactura],
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

      @id = params.delete(:idFactura) || params.delete(:id)
      @number = params.delete(:nroFactura) || params.delete(:number)
      @cae = params.delete(:cae)

      @items = parse_items(params.delete(:itemsFactura))
      @payments = parse_payments(params.delete(:ItemsCobro))
      @taxes_totals = parse_taxes_totals(params.delete(:totalesiva))

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

    def editable?
      cae.nil? || cae.empty?
    end

    def url
      return if @data[:url].nil? || @data[:url].empty?

      "#{@data[:url]}?usuario=#{@client.username}&claveSesion=#{@client.session_key}&idEmpresa=#{company_id}&idFactura=#{id}&idCliente=#{customer_id}"
    end

    def total_charged
      @items.map(&:total_charged).inject(0,:+)
    end

    def []=(key, value)
      ensure_editability!

      super
    end

    def customer=(new_customer)
      @customer = new_customer if new_customer.is_a?(Colppy::Customer)
    end

    def save
      ensure_editability!
      ensure_client_valid!
      ensure_payment_setup!

      response = @client.call(
        :sell_invoice,
        :create,
        save_parameters
      )
      if response[:success]
        @cae = response[:cae]
        @id = response[:idfactura]
        @number = response[:nroFactura]
        @data[:invoice_date] = response[:fechaFactura]
        @data[:url] = response[:UrlFacturaPdf]
        self
      else
        false
      end
    end

    private

    def attr_inspect
      [:id, :number, :cae]
    end

    def customer_id
      return @customer.id if @customer

      @data[:customer_id] || ""
    end
    def company_id
      return @company.id if @company

      @data[:company_id] || ""
    end
    def payment_condition_id
      validate_type!(:payment_condition_id, VALID_PAYMENT_CONDITIONS)
    end
    def previous_status_id
      if status = @data[:previous_status_id]
        validate_type!(status, VALID_STATUS_ID)
      else
        ""
      end
    end
    def status_id
      validate_type!(:status_id, VALID_STATUS_ID)
    end
    def receipt_type_id
      validate_type!(:receipt_type_id, VALID_RECEIPT_TYPES)
    end
    def invoice_type_id
      validate_type!(:invoice_type_id, VALID_INVOICE_TYPES)
    end
    def invoice_type
      if receipt_type_id == "8"
        "Contado"
      end
    end
    def validate_type!(data_key, valid_types)
      type = @data[data_key]
      if type && valid_types.include?(type)
        type
      else
        raise DataError.new("The #{data_key} is invalid. The value should be any of this ones: #{valid_types.join(", ")}")
        ""
      end
    end

    def save_parameters
      charged_amounts = calculate_charged_amounts
      [
        @client.session_params,
        general_params(charged_amounts),
        itemsFactura: @items.map(&:save_parameters),
        ItemsCobro: @payments.map(&:save_parameters),
        totalesiva: @taxes_totals.map(&:save_parameters)
      ].inject(&:merge)
    end

    def general_params(charged_amounts)
      {
        idCliente: customer_id,
        idEmpresa: company_id,
        idUsuario: @client.username,
        descripcion: @data[:descripcion] || "",
        fechaFactura: valid_date(@data[:invoice_date]),
        idCondicionPago: payment_condition_id,
        fechaPago: valid_date(@data[:payment_date]),
        idEstadoAnterior: previous_status_id,
        idEstadoFactura: status_id,
        idFactura: @id || "",
        idMoneda: @data[:currency_id] || "1",
        idTipoComprobante: receipt_type_id,
        idTipoFactura: invoice_type_id,
        netoGravado: charged_amounts[:total_taxed] || 0.00,
        netoNoGravado: charged_amounts[:total_non_taxed] || 0.00,
        nroFactura1: @data[:invoice_number1] || "0001",
        nroFactura2: @data[:invoice_number2] || "00000000",
        percepcionIVA: @data[:tax_perception] || 0.00,
        percepcionIIBB: @data[:iibb_perception] || 0.00,
        totalFactura: charged_amounts[:total] || 0.00,
        totalIVA: charged_amounts[:tax_total] || 0.00,
        valorCambio: @data[:exchange_rate] || "1",
        nroRepeticion: @data[:repetition_number] || "1",
        periodoRep: @data[:repetition_period] || "1",
        nroVencimiento: @data[:expiration_number] || "0",
        tipoVencimiento: @data[:expiration_type] || "1",
        fechaFin: @data[:end_date] || ""
      }.tap do |params|
        params[:tipoFactura] = invoice_type if invoice_type
        if status_id == "Cobrada"
          params[:totalpagadofactura] = @payments.map(&:amount).inject(0,:+)
        end
        params[:labelfe] = "Factura Electrónica" if @data[:electronic_bill]
      end
    end

    def calculate_charged_amounts
      if @items.nil? || @items.empty?
        raise DataError.new("In order to save an SellInvoice you should at least have one item in it. Add one with .add_item()")
      else
        charged_details = @items.each_with_object(base_charged_amounts) do |item, result|
          tax = item.tax
          total = item.total_charged
          if tax > 0
            dividend = tax.to_f
            divisor = (100.0 + dividend).to_f

            item_tax_amount = (( total * dividend ) / divisor).round(2)
            item_taxed_amount = (total - item_tax_amount).round(2)
            result[:tax_total] += item_tax_amount
            result[:total_taxed] += item_taxed_amount
            tax_breakdown_data = TaxTotal.add_to_tax_breakdown(
              tax,
              item_tax_amount,
              item_taxed_amount,
              result[:tax_breakdown][tax]
            )
            result[:tax_breakdown][tax] = tax_breakdown_data
          else
            result[:total_nontaxed] += total
          end
          result[:total] += total
        end
        @taxes_totals = parse_taxes_totals(charged_details[:tax_breakdown].values)
        charged_details
      end
    end

    def base_charged_amounts
      {
        total_taxed: 0.00,
        total_nontaxed: 0.00,
        total: 0.00,
        tax_total: 0.00,
        tax_breakdown: {}
      }
    end

    def ensure_editability!
      unless editable?
        raise ResourceError.new("You cannot change any value of this invoice, because it's already processed by AFIP. You should create a new one instead")
      end
    end

    def ensure_payment_setup!
      if status_id == "Cobrada" && (@payments.nil? || @payments.empty?)
        raise ResourceError.new("You cannot save this invoice, because it's doesn't have any payment associated to it and the status is #{@data[:status_id]}. Add one calling .add_payment({})")
      end
    end
  end
end

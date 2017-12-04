module Colppy
  class CreditNote < SellInvoice

    ATTRIBUTES_MAPPER = {
      idEmpresa: :company_id,
      idCliente: :customer_id,
      descripcion: :description,
      fechaFactura: :invoice_date,
      idEstadoAnterior: :previous_status_id, # validate
      idEstadoFactura: :status_id, # validate
      idMoneda: :currency_id,
      idTipoComprobante: :receipt_type_id, # validate
      idTipoFactura: :invoice_type_id,
      idUsuario: :user_id, # No aparece en la documentación
      netoGravado: :total_taxed,
      netoNoGravado: :total_nontaxed,
      nroFactura1: :invoice_number1,
      nroFactura2: :invoice_number2,
      percepcionIVA: :tax_perception,
      percepcionIIBB: :iibb_perception,
      saldoaaplicar: :balance_apply,  #new value require
      totalFactura: :total, # require
      totalIVA: :total_taxes, #require
      totalaplicado: :total_apply, # new value require
      valorCambio: :exchange_rate
    }.freeze

    def initialize(client: nil, company: nil, customer: nil, **params)
      @client = client if client && client.is_a?(Colppy::Client)
      @company = company if company && company.is_a?(Colppy::Company)
      @customer = customer if customer && customer.is_a?(Colppy::Customer)
      @items = parse_items(params.delete(:itemsFactura))
      super(params)
    end

    def save
      ensure_editability!
      ensure_client_valid!

      response = @client.call(
        :sell_invoice,
        :create,
        save_parameters
      )

      if response.present? && response[:success]
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

    def receipt_type_id
      validate_type!(:receipt_type_id, VALID_RECEIPT_TYPES)
    end

    def general_params(charged_amounts)
      {
        idCliente: customer_id,
        idEmpresa: company_id,
        idUsuario: @client.username,
        descripcion: @data[:description] || "",
        fechaFactura: valid_date(@data[:invoice_date]),
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
        saldoaaplicar: @data[:balance_apply] || 0.00,
        totalaplicado: @data[:total_apply] || 0.00
      }.tap do |params|
        params[:tipoFactura] = invoice_type if invoice_type
        if status_id == "Cobrada"
          params[:totalpagadofactura] = @payments.map(&:amount).inject(0,:+)
        end
      end
    end
  end
end

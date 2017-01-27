module Colppy
  class Invoice < Resource
    VALID_PAYMENT_CONDITIONS = ["Contado", "a 15 Dias", "a 30 Dias", "a 60 Dias"]
    VALID_STATUS_ID = [ "Borrador", "Aprobada", "Anulada", "Cobrada" ]
    VALID_INVOICE_TYPES = %w(A B C E Z I M X)

    def add_item(params)
      if item = Item.new(params, @company)
        @items << item
      end
    end
    def remove_item(key, value)
      @items.delete_if do |item|
        item.send(key.to_sym).to_s == value.to_s
      end
    end

    def add_payment(params)
      if payment = Payment.new(params)
        @payments << payment
      end
    end

    private

    def parse_items(new_items)
      return [] if new_items.nil? || new_items.empty?

      new_items.map do |item_data|
        Item.new(item_data, @company)
      end
    end

    def parse_payments(new_payments)
      return [] if new_payments.nil? || new_payments.empty?

      new_payments.map do |payment_data|
        Payment.new(payment_data)
      end
    end

    def parse_taxes_totals(new_taxes_totals)
      return [] if new_taxes_totals.nil? || new_taxes_totals.empty?

      new_taxes_totals.map do |tax_total_data|
        TaxTotal.new(tax_total_data)
      end
    end

    def invoice_status
      type = @data[:idEstadoFactura]
      if type && VALID_INVOICE_STATUS.include?(type)
        type
      else
        raise DataError.new("The value of idEstadoFactura=#{type} is invalid. The value should be any of this ones: #{VALID_INVOICE_STATUS.join(", ")}")
      end
    end

    def invoice_type
      type = @data[:idTipoFactura]
      if type && VALID_INVOICE_TYPES.include?(type)
        type
      else
        raise DataError.new("The idTipoFactura=#{type} is invalid. The value should be any of this ones: #{VALID_INVOICE_TYPES.join(", ")}")
      end
    end
  end

  class Invoice::Item
    attr_reader :id, :data
    include Utils

    ATTRIBUTES_MAPPER = {
      idItem: :product_id,
      minimo: :minimum_stock,
      tipoItem: :item_type,
      codigo: :codigo,
      Descripcion: :name,
      unidadMedida: :measure_unit,
      Cantidad: :quantity, # required
      ImporteUnitario: :unit_price,
      IVA: :tax,
      porcDesc: :discount_percentage,
      subtotal: :subtotal,
      idPlanCuenta: :sales_account_id,
      Comentario: :comment
    }.freeze
    PROTECTED_DATA_KEYS = [:product_id].freeze
    DATA_KEYS_SETTERS = (ATTRIBUTES_MAPPER.values - PROTECTED_DATA_KEYS).freeze

    def initialize(params, company = nil)
      @company = company if company.is_a?(Colppy::Company)

      @id = params.delete(:id)
      @product = params.delete(:product)
      @data = rename_params_hash(params, ATTRIBUTES_MAPPER, DATA_KEYS_SETTERS)

      if @product && @product.is_a?(Colppy::Product)
        @data[:product_id] = @product.id
      else
        @product = nil
      end
      self
    end

    DATA_KEYS_SETTERS.each do |data_key|
      define_method("#{data_key}") do
        @data[data_key.to_sym]
      end
      define_method("#{data_key}=") do |value|
        @data[data_key.to_sym] = value
      end
    end

    def unhandle_data
      @data[:unhandle] || {}
    end

    def product
      @product ||= @company.product(@data[:product_id])
    end

    def product_id=(value)
      @product = nil
      @data[:product_id] = value
    end
    def product_id
      @data[:product_id]
    end

    def tax
      tax = product.present? ? product.tax : nil
      (@data[:tax] || tax || 21).to_f
    end
    def charged
      if (percentage = discount_percentage.to_f) > 0
        unit_price * ((100 - percentage) / 100)
      else
        unit_price
      end
    end
    def unit_price
      (@data[:unit_price] || product.sell_price || 0).to_f
    end
    def quantity
      @data[:quantity] || 0
    end
    def total_charged
      ( charged * quantity ).round(2)
    end
    def minimum_stock
      (@data[:minimum_stock] || product.minimum_stock || 0)
    end
    def item_type
      (@data[:item_type] || product.item_type || "P")
    end
    def code
      (@data[:code] || product.code || "")
    end
    def name
      (@data[:name] || product.name || "")
    end
    def measure_unit
      (@data[:measure_unit] || product.measure_unit || "u")
    end
    def sales_account_id
      (@data[:sales_account_id] || product.sales_account || "")
    end
    def comment
      (@data[:comment] || "#{product.name}, #{product.detail}"  || "")
    end

    def save_parameters
      {
        idItem: product_id.to_s,
        minimo: minimum_stock.to_s,
        tipoItem: item_type,
        codigo: code,
        Descripcion: name,
        ccosto1: unhandle_data[:ccosto1] || "",
        ccosto2: unhandle_data[:ccosto2] || "",
        almacen: unhandle_data[:almacen] || "",
        unidadMedida: measure_unit,
        Cantidad: quantity,
        ImporteUnitario: unit_price.round(2),
        porcDesc: discount_percentage || 0,
        IVA: tax.to_s,
        subtotal: total_charged,
        idPlanCuenta: sales_account_id,
        Comentario: comment
      }
    end

    def inspect
      "#<#{self.class.name} product_id:#{@data[:product_id]} >"
    end
  end
  class Invoice::Payment
    include Utils

    VALID_PAYMENT_TYPES = [
      "Cheque Recibido Común",
      "Cheque Recibido Diferido",
      "Transferencia",
      "Efectivo",
      "Tarjeta de Credito"
    ]

    ATTRIBUTES_MAPPER = {
      idMedioCobro: :payment_type_id, # required
      idPlanCuenta: :payment_account_id, # required
      Banco: :bank,
      nroCheque: :check_number,
      fechaValidez: :valid_date,
      importe: :amount, # required
      VAD: :vad,
      Conciliado: :conciliated,
      idTabla: :table_id,
      idElemento: :element_id,
      idItem: :item_id
    }.freeze
    DATA_KEYS_SETTERS = ATTRIBUTES_MAPPER.values

    def initialize(params)
      @data = rename_params_hash(params, ATTRIBUTES_MAPPER, DATA_KEYS_SETTERS)
    end
    DATA_KEYS_SETTERS.each do |data_key|
      define_method("#{data_key}=") do |value|
        @data[data_key.to_sym] = value
      end
    end

    def amount
      @data[:amount] || 0.0
    end

    def save_parameters
      {
        idMedioCobro: @data[:payment_type_id],
        idPlanCuenta: @data[:payment_account_id],
        Banco: @data[:bank] || "",
        nroCheque: @data[:check_number] || "",
        fechaValidez: @data[:valid_date] || "",
        importe: amount,
        VAD: @data[:vad] || "S",
        Conciliado: @data[:conciliated] || "",
        idTabla: @data[:table_id] || 0,
        idElemento: @data[:element_id] || 0,
        idItem: @data[:item_id] || 0
      }
    end

    def inspect; end
  end
  class Invoice::TaxTotal
    include Utils

    def self.add_to_tax_breakdown(tax, amount, taxed_amount, breakdown = nil)
      breakdown = breakdown || { tax_factor: tax, tax_amount: 0.0, taxed_amount: 0.0 }
      breakdown[:tax_amount] += amount
      breakdown[:taxed_amount] += taxed_amount
      breakdown
    end

    ATTRIBUTES_MAPPER = {
      alicuotaIva: :tax_factor,
      importeIva: :tax_amount,
      baseImpIva: :taxed_amount
    }.freeze
    DATA_KEYS_SETTERS = ATTRIBUTES_MAPPER.values

    def initialize(params)
      @data = rename_params_hash(params, ATTRIBUTES_MAPPER, DATA_KEYS_SETTERS)
    end
    DATA_KEYS_SETTERS.each do |data_key|
      define_method("#{data_key}=") do |value|
        @data[data_key.to_sym] = value
      end
    end

    def tax_name
      if @data[:tax_factor] % 1 == 0
        @data[:tax_factor].to_i.to_s
      else
        @data[:tax_factor].to_s
      end
    end

    def save_parameters
      {
        alicuotaIva: tax_name,
        importeIva: @data[:tax_amount],
        baseImpIva: @data[:taxed_amount]
      }
    end

    def inspect; end
  end
end

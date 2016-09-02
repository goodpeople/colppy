module Colppy
  class Resource
    attr_reader :data
    include Utils

    class << self
      protected

      def parse_list_response(results, total, call_parameters)
        per_page = call_parameters[:limit] || 50
        offset = call_parameters[:start] || 0
        page, total_pages = pages_calculation(offset, per_page, total)
        {
          offset: offset,
          total: total,
          page: page,
          per_page: per_page,
          total_pages: total_pages,
          results: results
        }
      end

      private

      def pages_calculation(offset, per_page, total)
        total_pages = ( total.to_f / per_page.to_f ).ceil
        remaining_pages = ((total - offset).to_f / per_page.to_f).floor
        [(total_pages - remaining_pages), total_pages]
      end
    end

    def initialize(params)
      @data = rename_params_hash(
        params,
        self.class::ATTRIBUTES_MAPPER,
        self.class::DATA_KEYS_SETTERS
      )
    end

    def inspect
      formatted_attrs = attr_inspect.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class.name} #{formatted_attrs.join(", ")}>"
    end

    def []=(key, value)
      key_sym = key.to_sym
      if PROTECTED_DATA_KEYS.include?(key_sym)
        raise ResourceError.new("You cannot change any of this values: #{PROTECTED_DATA_KEYS.join(", ")} manually")
      end
      if DATA_KEYS_SETTERS.include?[key]
        @data[key_sym] = value
      elsif new_key = ATTRIBUTES_MAPPER[key_sym]
        @data[new_key] = value if DATA_KEYS_SETTERS.include?(new_key)
      else
        raise DataError.new("There is no attribute named :#{key_sym}, or you cannot change it manually this way. Try initializing another #{self.class.name} with that attribute as the argument")
      end
    end

    private

    def attr_inspect
    end

    def valid_date(date_string)
      return today_date_string if date_string.nil? || date_string.empty?

      parsed_date = Date.parse(date_string)
      if parsed_date <= Date.today
        date_string
      else
        today_date_string
      end
    end

    def today_date_string
      Date.today.strftime("%d-%m-%Y")
    end

    def ensure_client_valid!
      unless @client && @client.is_a?(Colppy::Client)
        raise ResourceError.new(
          "You should provide a client, and it should be a Colppy::Client instance"
        )
      end
    end

    def ensure_company_valid!
      unless @company && @company.is_a?(Colppy::Company)
        raise ResourceError.new(
          "You should provide a company, and it should be a Colppy::Company instance"
        )
      end
    end

    def ensure_customer_valid!
      unless @customer && @customer.is_a?(Colppy::Customer)
        raise ResourceError.new(
          "You should provide a customer, and it should be a Colppy::Customer instance"
        )
      end
    end
  end
end

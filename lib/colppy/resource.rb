module Colppy
  class Resource
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

    def inspect
      formatted_attrs = attr_inspect.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class.name} #{formatted_attrs.join(", ")}>"
    end

    private

    def attr_inspect
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

  end
end

module Colppy
  module Core
    class Gateway
      MODES = %w(live sandbox).freeze
      MIME_JSON = "application/json".freeze
      SANDBOX_API_URL = "http://staging.colppy.com".freeze
      PRODUCTION_API_URL = "https://login.colppy.com".freeze
      API_PATH = "/lib/frontera2/service.php".freeze

      def initialize(mode = "sandbox")
        @mode = mode
      end
      MODES.each do |mode_name|
        define_method("#{mode_name}!") do
          @mode = mode_name
        end
        define_method("#{mode_name}?") do
          @mode == mode_name
        end
      end

      def call(payload = {})
        make_request(payload)
      end

      private

      def headers
        {
          'User-Agent' => "Colppy Ruby Gem v#{Colppy::VERSION}",
          content_type: MIME_JSON,
          accept: MIME_JSON
        }
      end

      def make_request(payload)
        unless payload.empty?
          payload = MultiJson.dump(payload)
        end
        response = connection.post do |call|
          call.url API_PATH
          call.headers = headers
          unless payload.empty?
            call.body = payload
          end
        end

        MultiJson.load(response.body, symbolize_keys: true)
      rescue Exception => e
        if e.respond_to?(:response)
          MultiJson.load(e.response, symbolize_keys: true)
        else
          raise e
        end
      end

      def connection
        Faraday.new(endpoint_url) do |faraday|
          faraday.adapter(Faraday.default_adapter)
        end
      end

      def endpoint_url
        case @mode
        when "live" then PRODUCTION_API_URL
        when "sandbox" then SANDBOX_API_URL
        else
          SANDBOX_API_URL
        end
      end

    end
  end
end

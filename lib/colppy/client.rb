module Colppy
  class Client
    extend Forwardable
    include Digest
    SERVICES_MANIFEST = Core::SERVICES.freeze

    def initialize(auth_user, auth_pass, user, mode = "sandbox")
      ensure_user_valid!(user)

      @auth_user = auth_user
      @auth_pass = md5(auth_pass)
      @gateway = Core::Gateway.new(mode)
      if user
        @user = user
        sign_in
      end
    end
    def_delegators :@gateway, :live!, :live?, :sandbox!, :sandbox?

    def inspect
      formatted_attrs = attr_inspect.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class.name} #{formatted_attrs.join(", ")}>"
    end

    include CompanyActions
    include UserActions

    def call(service, operation, params)
      request_payload = request_base(service, operation).merge(parameters: params)

      @gateway.call(request_payload)[:response] if request_payload
    end

    private

    def attr_inspect
      [:session_key]
    end

    def request_base(service, operation)
      service = request_for!(service, operation)

      {
        auth: {
          usuario: @auth_user,
          password: @auth_pass
        },
        service: service
      }
    end

    def request_for!(service, operation)
      unless SERVICES_MANIFEST.keys.include?(service)
        error = "There is no :#{service} service. The available ones are: " \
                "[:#{SERVICES_MANIFEST.keys.join(', :')}]"
        raise ServiceError.new(error)
      end
      service = SERVICES_MANIFEST[service]

      unless service.keys.include?(operation)
        error = "There is no operation called :#{operation}. The available operations are: "\
                "[:#{service.keys.join(', :')}]"
        raise ServiceError.new(error)
      end
      service[operation]
    end

  end
end

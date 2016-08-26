module Colppy
  class Resource
    include Utils

    def inspect
      formatted_attrs = attr_inspect.map do |attr|
        "#{attr}: #{send(attr).inspect}"
      end
      "#<#{self.class.name} #{formatted_attrs.join(", ")}>"
    end

    private

    def attr_inspect
    end

  end
end

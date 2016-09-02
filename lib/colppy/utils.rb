module Colppy
  module Utils
    module_function

    ATTRIBUTES_MAPPER = {}
    DATA_KEYS_SETTERS = []

    def rename_params_hash(params, mapper, setter)
      params.each_with_object({}) do |(key, value), hash|
        if new_key = mapper[key]
          hash[new_key] = value
        elsif setter.include?(key)
          hash[key] = value
        else
          hash[:unhandle] ||= {}
          hash[:unhandle][key] = value
        end
      end
    end
  end
end

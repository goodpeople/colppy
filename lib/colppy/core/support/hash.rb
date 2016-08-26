# # Taken from https://github.com/futurechimp/plissken because that gem
# # has a dependency on symbolize -> Active**

module Colppy
  module Core
    # Colppy::Core::Hash.snakecase_keys(value)
    module Hash
      extend self
      # Recursively converts CamelCase and camelBack JSON-style hash keys to
      # Rubyish snake_case, suitable for use during instantiation of Ruby
      # model attributes.
      #
      def snakecase_keys(value)
        case value
        when(Array)
          value.map { |v| snakecase_keys(v) }
        when(::Hash)
          snake_hash(value)
        else
          value
        end
      end

      private

      def snake_hash(value)
        ::Hash[value.map { |k, v| [snake_key(k).to_sym, snakecase_keys(v)] }]
      end

      def snake_key(k)
        if k.is_a? Symbol
          snakecase(k.to_s).to_sym
        elsif k.is_a? String
          snakecase(k)
        else
          k # Can't snakify anything except strings and symbols
        end
      end

      def snakecase(string)
        string.gsub(/::/, '/')
          .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
          .gsub(/([a-z\d])([A-Z])/, '\1_\2')
          .tr('-', '_')
          .downcase
      end
    end
  end
end

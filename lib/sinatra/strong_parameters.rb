require 'sinatra/base'
require 'hashie'

module Sinatra
  module StrongParameters

    class ParameterMissing < StandardError
      attr_reader :param

      def initialize(param)
        @param = param
        super("param is missing or the value is empty: #{param}")
      end

    end

    class UnpermittedParameters < StandardError
      attr_reader :params

      def initialize(params)
        @params = params
        super("found unpermitted parameters: #{params.join(', ')}")
      end
    end

    class Parameters < Hash
      include Hashie::Extensions::IndifferentAccess

      attr_accessor :permitted
      alias :permitted? :permitted

      def initialize(attributes = nil)
        super
        update(attributes) unless attributes.nil?

        # For nested values that need to be turned into parameters
        # in order to chain method calls.
        each_pair do |key, value|
          convert_hashes_to_parameters(key, value) if value.is_a? Hash
        end

        @permitted = false
      end

      # invoked from <permit>
      def permit!
        each_pair do |key, value|
          wrap(value).each do |val|
            # if this value is an instance of parameters, call permit! 
            # recursively.
            val.permit! if val.respond_to? :permit!
          end 
        end

        @permitted = true
        self
      end 

      def require(key)
        presence(self[key]) || raise(ParameterMissing.new(key))
      end

      def [](key)
        convert_hashes_to_parameters(key, super)
      end

      def permit(*filters)
        params = self.class.new

        filters.each do |filter|
          case filter
            when Symbol 
              permitted_scalar_filter(params, filter)
            # TODO
            #when Hash
            end
        end

        unpermitted_parameters!(params)

        params.permit!
      end

      private

      def presence(val)
        val unless !val.respond_to?(:empty) ? !!val.empty? : !val
      end

      def wrap(obj)
        if obj.nil?
          []
        elsif obj.respond_to?(:to_ary)
          obj.to_ary || [obj]
        else
          [obj]
        end
      end

      def convert_hashes_to_parameters(key, value)
        converted = convert_value_to_parameters(value)
        self[key] = converted if !converted.equal?(value)
        converted
      end

      def convert_value_to_parameters(value)
        if value.is_a? Array
          value.map { |_| convert_value_to_parameters(_) }
        elsif value.is_a?(Parameters) || !value.is_a?(Hash)
          value
        else
          self.class.new(value)
        end
      end

      def permitted_scalar_filter(params, key)
        params[key] = self[key] if has_key?(key)
      end

      def unpermitted_parameters!(params)
        unpermitted_keys = unpermitted_keys(params)

        if unpermitted_keys.any?
          raise UnpermittedParameters.new(unpermitted_keys)
        end
      end

      def unpermitted_keys(params)
        self.keys - params.keys
      end
      
    end

    # entry point
    def strong_params
      Parameters.new(params)
    end

  end # end StrongParameters
  
  helpers StrongParameters

end # end Sinatra

require 'sinatra/base'
require 'hashie'
require 'byebug'

module Sinatra
  module StrongParameters

    class IndifferentHash < Hash
      include Hashie::Extensions::IndifferentAccess

      def initialize(attributes = nil)
        super
        update(attributes) unless attributes.nil?
      end
      
      def slice(*keys)
        keys.map! { |key| convert_key(key) } if respond_to?(:convert_key, true)
        keys.each_with_object(self.class.new) { |k, hash| hash[k] = self[k] if has_key?(k) }
      end
    end

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

    class Parameters < IndifferentHash 
      attr_accessor :permitted
      attr_accessor :raise_unpermitted
      alias :permitted? :permitted
      
      def initialize(attributes = nil, raise_flag = false)
        @raise_unpermitted = raise_flag
        super(attributes)
        update(attributes) unless attributes.nil?

        # For nested values that need to be turned into parameters
        # in order to chain method calls.
        each_pair do |key, value|
          convert_hashes_to_parameters(key, value) if value.is_a? Hash
        end

        @permitted = false
      end

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

        filters.flatten.each do |filter|
          case filter
          when Symbol, String 
            permitted_filter(params, filter)
          when Hash
            hash_filter(params, filter) 
          end
        end

        unpermitted_parameters!(params) if @raise_unpermitted

        params.permit!
      end

      private

      def presence(val)
        val unless !val.respond_to?(:empty) ? !!val.empty? : !val
      end

      def slice(*keys)
        self.class.new(super).tap do |new_instance|
          new_instance.instance_variable_set :@permitted, @permitted
        end
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

      # TODO: See if the type is in the permitted scalar values
      def permitted_filter(params, key)
        params[key] = self[key] if has_key? key
      end

      def array_permitted_filter(params, key, hash = self)
        params[key] = hash[key] if hash.has_key? key
      end

      def hash_filter(params, filter)
        filter = IndifferentHash.new(filter)
       
        # slice removes non-declared keys.
        slice(*filter.keys).each do |key, value|
          # filtered out
          next unless value

          if filter[key] == []
            # { comment_ids: [].
            array_permitted_filter(params, key)
          else
            # { user: name } or { user: [ :name, :age, { address: ... }]}.
            params[key] = each_element(value) do |element, index|
              if element.is_a? Hash
                element = self.class.new(element) unless element.respond_to?(:permit)
                element.permit(wrap(filter[key]))
              elsif filter[key].is_a?(Hash) && filter[key][index] == []
                array_permitted_filter(params, index, value)
              end
            end
          end
        end
      end 

      def each_element(value)
        if value.is_a?(Array)
          value.map { |el| yield el }.compact
        elsif fields_for_style?(value)
          hash = value.class.new
          value.each { |key, val| key=~ /\A-?\d+/ && val.is_a?(Hash) }
          hash
        else
          yield value
        end
      end

      def fields_for_style?(object)
        object.is_a?(Hash) && object.all? { |k, v| k =~ /\A-?\d+\z/ && v.is_a?(Hash) }
      end  

      def unpermitted_parameters!(params)
        unpermitted_keys = unpermitted_keys(params)
        if unpermitted_keys.any? && @raise_unpermitted
          raise UnpermittedParameters.new(unpermitted_keys)
        end
      end

      def unpermitted_keys(params)
        self.keys - params.keys
      end
      
    end

    # entry point
    def strong_params
      flag = settings.respond_to?(:raise_unpermitted) ? settings.raise_unpermitted : false
      Parameters.new(params, flag)
    end

  end # end StrongParameters
  
  helpers StrongParameters

end # end Sinatra

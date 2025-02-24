# frozen_string_literal: true

module Doorkeeper
  module JWT
    class MissingConfiguration < StandardError
      def initialize
        super("Configuration for doorkeeper-jwt missing.")
      end
    end

    def self.configure(&block)
      @config = Config::Builder.new(&block).build
    end

    def self.configuration
      @config || raise(MissingConfiguration)
    end

    class Config
      class Builder
        def initialize(&block)
          @config = Config.new
          instance_eval(&block)
        end

        def build
          @config
        end

        def use_application_secret(value)
          @config.instance_variable_set("@use_application_secret", value)
        end

        def secret_key(value)
          @config.instance_variable_set("@secret_key", value)
        end

        def secret_key_path(value)
          @config.instance_variable_set("@secret_key_path", value)
        end

        # For backward compatibility. This library does not support encryption.
        def encryption_method(value)
          @config.instance_variable_set("@signing_method", value)
        end

        def signing_method(value)
          @config.instance_variable_set("@signing_method", value)
        end
      end

      module Option
        # Defines configuration options.
        #
        # When you call option, it defines two methods. One method will take
        # place in the +Config+ class and the other method will take place in
        # the +Builder+ class.
        #
        # The +name+ parameter will set both builder method and config
        # attribute. If the +:as+ option is defined, the builder method will be
        # the specified option while the config attribute will be the +name+
        # parameter.
        #
        # If you want to introduce another level of config DSL you can define
        # +builder_class+ parameter. Builder should take a block as the
        # initializer parameter and respond to function +build+ that returns the
        # value of the config attribute.
        #
        # ==== Options
        #
        # * [+:as+] Set the builder method that goes inside +configure+ block.
        # * [+:default+] The default value in case no option was set.
        #
        # ==== Examples
        #
        #     option :name
        #     option :name, as: :set_name
        #     option :name, default: 'My Name'
        #     option :scopes, builder_class: ScopesBuilder
        def option(name, options = {})
          attribute = options[:as] || name
          attribute_builder = options[:builder_class]
          attribute_symbol = :"@#{attribute}"

          Builder.instance_eval do
            define_method name do |*args, &block|
              # TODO: is builder_class option being used?
              value =
                if attribute_builder
                  attribute_builder.new(&block).build
                else
                  block || args.first
                end

              @config.instance_variable_set(attribute_symbol, value)
            end
          end

          define_method attribute do |*|
            if instance_variable_defined?(attribute_symbol)
              instance_variable_get(attribute_symbol)
            else
              options[:default]
            end
          end

          public attribute
        end

        def extended(base)
          base.send(:private, :option)
        end
      end

      extend Option

      option(
        :token_payload,
        default: proc { { token: SecureRandom.method(:hex) } }
      )

      option :token_headers, default: proc { {} }
      option :use_application_secret, default: false
      option :secret_key, default: nil
      option :secret_key_path, default: nil
      option :signing_method, default: nil

      def use_application_secret
        @use_application_secret ||= false
      end

      def secret_key
        @secret_key ||= nil
      end

      def secret_key_path
        @secret_key_path ||= nil
      end

      def signing_method
        @signing_method ||= nil
      end
    end
  end
end

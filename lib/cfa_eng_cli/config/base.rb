# frozen_string_literal: true

require 'configsl'

module CfaEngCli
  module Config
    # Base configuration class for the CLI.
    #
    # @abstract
    class Base < ConfigSL::Config
      # Serializes the current configuration for storage.
      #
      # @return [Hash]
      def serialize
        values.to_h do |option, value|
          serialize_option(option, value)
        end
      end

      # Serialize the value for a single option.
      def serialize_option(option, value)
        return [option.to_s, value] unless collection?(option)

        serialized = if options[option][:type] == Hash
                       value.to_h { |k, v| [k.to_s, v.serialize] }
                     else
                       value.map(&:serialize)
                     end

        [option.to_s, serialized]
      end
    end
  end
end

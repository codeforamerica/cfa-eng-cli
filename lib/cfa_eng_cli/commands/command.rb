# frozen_string_literal: true

require 'configsl'
require 'thor'

module CfaEngCli
  module Commands
    # Base class for all CLI commands.
    class Command < Thor
      private

      # Prompts the user for a parameter value.
      #
      # Nested configuration options (i.e. those whose type is itself a
      # ConfigSL::Config) are prompted for recursively rather than as a flat
      # string.
      #
      # @param opts [Hash] Options for the parameter to prompt for.
      # @return [Object] Provided or default value of the parameter.
      def prompt_for_parameter(opts)
        return prompt_for_config(opts) if opts[:type].is_a?(Class) && opts[:type] < ConfigSL::Config

        value = ask("#{opts[:prompt]} [#{opts[:default] if opts[:default]}]:")
        value.empty? ? opts[:default] : value
      end

      # Prompts the user for each option of a nested configuration class.
      #
      # @param opts [Hash] Options for the nested configuration parameter.
      # @return [ConfigSL::Config, nil] Constructed nested configuration, or
      #   nil if an optional nested configuration is declined.
      def prompt_for_config(opts)
        type = opts[:type]
        return nil if !opts[:required] && !yes?("Configure #{type.name.split('::').last}?")

        params = type.options.each_with_object({}) do |(name, sub_opts), memo|
          memo[name] = prompt_for_parameter(sub_opts)
        end

        type.new(params)
      end
    end
  end
end

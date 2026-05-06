# frozen_string_literal: true

require 'thor'

module CfaEngCli
  module Commands
    # Base class for all CLI commands.
    class Command < Thor
      private

      # Prompts the user for a parameter value.
      #
      # @param opts [Hash] Options for the parameter to prompt for.
      # @return [String] Provided or default value of the parameter.
      def prompt_for_parameter(opts)
        value = ask("#{opts[:prompt]} [#{opts[:default] if opts[:default]}]:")
        value.empty? ? opts[:default] : value
      end
    end
  end
end

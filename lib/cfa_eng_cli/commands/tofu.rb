# frozen_string_literal: true

require 'shellwords'

require_relative 'command'
require_relative '../config/profile'
require_relative '../open_tofu'

module CfaEngCli
  module Commands
    # Commands for running OpenTofu operations.
    class Tofu < Command
      class_option :profile, type: :string, required: true, default: ENV.fetch('CFA_PROFILE', nil)
      class_option :var, type: :array,
                         desc: 'Variable to set (e.g. --var application=foo). ' \
                               'Passed to both tofu init and the subcommand. ' \
                               'Can be specified multiple times.'

      desc 'plan CONFIG', 'Run tofu plan for the given configuration layer'
      option :args, type: :string, desc: 'Extra arguments to pass to tofu plan (e.g. "-out tfplan")'
      def plan(config)
        profile = load_profile
        print_environment_warning(profile.environment)
        open_tofu(profile).plan(config, args: extra_args, vars: var_args)
      end

      desc 'apply CONFIG', 'Run tofu apply for the given configuration layer'
      option :args, type: :string, desc: 'Extra arguments to pass to tofu apply'
      def apply(config)
        profile = load_profile
        print_environment_warning(profile.environment)
        open_tofu(profile).apply(config, args: extra_args, vars: var_args)
      end

      desc 'destroy CONFIG', 'Run tofu destroy for the given configuration layer'
      option :args, type: :string, desc: 'Extra arguments to pass to tofu destroy'
      def destroy(config)
        profile = load_profile
        print_environment_warning(profile.environment)
        open_tofu(profile).destroy(config, args: extra_args, vars: var_args)
      end

      desc 'output CONFIG', 'Show outputs for the given configuration layer'
      option :args, type: :string, desc: 'Extra arguments to pass to tofu output (e.g. "-json")'
      def output(config)
        profile = load_profile
        open_tofu(profile).output(config, args: extra_args, vars: var_args)
      end

      desc 'force-unlock CONFIG LOCK_ID', 'Force-unlock the state for the given configuration layer'
      def force_unlock(config, lock_id)
        profile = load_profile
        print_environment_warning(profile.environment)
        open_tofu(profile).force_unlock(config, lock_id, vars: var_args)
      end

      desc 'bootstrap', 'Bootstrap the remote backend for the environment'
      def bootstrap
        profile = load_profile
        print_environment_warning(profile.environment)
        open_tofu(profile).bootstrap(project: profile.project, vars: var_args)
      end

      private

      # Loads the profile specified by --profile.
      #
      # @return [Config::Profile]
      def load_profile
        Config::Profile.load(options[:profile])
      end

      # Instantiates OpenTofu with settings from the given profile.
      #
      # @param profile [Config::Profile]
      # @return [OpenTofu]
      def open_tofu(profile)
        OpenTofu.new(profile.environment,
                     aws_profile: profile.aws_profile,
                     doppler_project: profile.doppler.project,
                     doppler_environment: profile.doppler.environment)
      end

      # Parses the --args option string into an array using shell-word splitting,
      # returning [] if absent. Shell quoting is respected so that values like
      # -var="key=value" are passed to tofu as a single unquoted argument.
      #
      # @return [Array<String>]
      def extra_args
        Shellwords.split(options[:args] || '')
      end

      # Converts --var values into pre-formatted tofu -var argument pairs.
      # ["application=foo", "region=us-east-1"] becomes
      # ["-var", "application=foo", "-var", "region=us-east-1"].
      #
      # @return [Array<String>]
      def var_args
        (options[:var] || []).flat_map { |v| ['-var', v] }
      end

      # Prints a color-coded message based on whether the environment is production.
      #
      # @param environment [String]
      def print_environment_warning(environment)
        if environment == 'production'
          puts "\e[0;31mWARNING: Running against production environment!\e[0m"
        else
          puts "\e[0;32mRunning against non-production environment \"#{environment}\".\e[0m"
        end
      end
    end
  end
end

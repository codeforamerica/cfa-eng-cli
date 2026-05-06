# frozen_string_literal: true

require_relative 'command'
require_relative '../bastion'
require_relative '../config/profile'
require_relative '../session_manager'

module CfaEngCli
  module Commands
    # Commands for interacting with bastion hosts.
    class Bastion < Command
      class_option :profile, type: :string, required: true, default: ENV.fetch('CFA_PROFILE', nil)

      desc 'create-tunnel', 'Create a new tunnel configuration'
      def create_tunnel
        profile = Config::Profile.load(options[:profile])
        params = collect_tunnel_params

        profile.tunnels[params[:name]] = Config::RemoteTunnel.new(params)
        profile.write
      end

      desc 'delete-tunnel NAME', 'Delete a tunnel configuration'
      def delete_tunnel(name)
        profile = Config::Profile.load(options[:profile])
        profile.tunnels.delete(name.to_sym)
        profile.write
      end

      desc 'tunnel', 'Open a tunnel to a remote host.'
      option :name, type: :string
      def tunnel
        profile = Config::Profile.load(options[:profile])
        config = profile.tunnels[options[:name].to_sym]
        raise Thor::Error, "No tunnel found for #{options[:name]}" if config.nil?

        open_tunnel(profile, config)
      end

      private

      # Collects the parameters for a new tunnel configuration.
      #
      # @return [Hash] The parameters for the new tunnel configuration.
      def collect_tunnel_params
        Config::RemoteTunnel.options.each_with_object({}) do |(name, opts), params|
          options[name] = prompt_for_parameter(opts) unless options[name]
          params[name] = options[name]
        end
      end

      # Opens a tunnel to the bastion for remote port forwarding.
      #
      # @param profile [Config::Profile] Profile to use for the bastion.
      # @param config [Config::RemoteTunnel] Configuration for the tunnel.
      def open_tunnel(profile, config)
        bastion = CfaEngCli::Bastion.new(profile)
        session = SessionManager.new(
          bastion.tunnel(config.remote_port, config.host, config.local_port)
        )

        session.open(bastion.target)
      end
    end
  end
end

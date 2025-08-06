# frozen_string_literal: true

require 'thor'

require_relative '../bastion'
require_relative '../config/profile'
require_relative '../session_manager'

module CfaEngCli
  module Commands
    # Commands for interacting with bastion hosts.
    class Bastion < Thor
      class_option :profile, type: :string, required: true, default: ENV.fetch('CFA_PROFILE', nil)

      desc 'create-tunnel', 'Create a new tunnel configuration'
      def create_tunnel
        params = {}
        profile = Config::Profile.load(options[:profile])
        Config::RemoteTunnel.options.each do |name, opts|
          unless options[name]
            value = ask("#{opts[:prompt]} [#{opts[:default] if opts[:default]}]:")
            options[name] = value.empty? ? opts[:default] : value
          end

          params[name] = options[name]
        end

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
        tunnel = profile.tunnels[options[:name].to_sym]
        raise Thor::Error, "No tunnel found for #{options[:name]}" if tunnel.nil?

        bastion = CfaEngCli::Bastion.new(profile)
        session = SessionManager.new(
          bastion.tunnel(tunnel.remote_port, tunnel.host, tunnel.local_port)
        )
        session.open(bastion.target)
      end
    end
  end
end

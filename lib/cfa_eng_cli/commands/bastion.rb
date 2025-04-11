# frozen_string_literal: true

require 'thor'

require_relative '../bastion'
require_relative '../config/profile'
require_relative '../session_manager'

module CfaEngCli
  module Commands
    # Commands for interacting with bastion hosts.
    class Bastion < Thor
      class_option :profile, type: :string, required: true

      desc 'tunnel', 'Open a tunnel to a remote host.'
      option :host, type: :string, required: true,
                    desc: 'Remote host to open a tunnel to'
      option :port, type: :numeric,
                    desc: 'Remote port to open a tunnel to', default: 443
      option :local_port, type: :numeric,
                          desc: 'Local port to listen on', default: 9000
      def tunnel
        profile = Config::Profile.load(options[:profile])
        bastion = CfaEngCli::Bastion.new(profile.project, profile.environment)
        session = SessionManager.new(bastion.tunnel(options[:port], options[:host], options[:local_port]))
        session.open(bastion.target)
      end
    end
  end
end

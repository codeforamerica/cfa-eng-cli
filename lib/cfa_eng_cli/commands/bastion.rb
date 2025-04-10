# frozen_string_literal: true

require_relative '../bastion'
require_relative '../session_manager'

module CfaEngCli
  module Commands
    # Commands for interacting with bastion hosts.
    class Bastion < Thor
      desc 'tunnel', 'Open a tunnel to a remote host.'
      option :project, type: :string, required: true,
                       desc: 'Name of the project to SSH into'
      option :environment, type: :string, required: true,
                           desc: 'Environment to SSH into (e.g. staging, production)'
      option :host, type: :string, required: true,
                    desc: 'Remote host to open a tunnel to'
      option :port, type: :numeric,
                    desc: 'Remote port to open a tunnel to', default: 443
      option :local_port, type: :numeric,
                          desc: 'Local port to listen on', default: 9000
      def tunnel
        bastion = CfaEngCli::Bastion.new(options[:project], options[:environment])
        session = SessionManager.new(bastion.tunnel(options[:port], options[:host], options[:local_port]))
        session.open(bastion.lookup.instance_id)
      end
    end
  end
end

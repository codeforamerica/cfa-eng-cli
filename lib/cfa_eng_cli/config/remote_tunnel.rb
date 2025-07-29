# frozen_string_literal: true

require_relative 'base'

module CfaEngCli
  module Config
    # Configuration for a remote tunnel.
    class RemoteTunnel < Base
      option :name, type: String, required: true, prompt: 'Tunnel name'
      option :local_port, type: Integer, default: 9000, prompt: 'Local port'
      option :remote_port, type: Integer, default: 443, prompt: 'Remote port'
      option :host, type: String, required: true, prompt: 'Host (without protocol)'
    end
  end
end

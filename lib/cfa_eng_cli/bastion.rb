# frozen_string_literal: true

require 'aws-sdk-ec2'
require 'aws-sdk-ssm'

module CfaEngCli
  # Manage and interact with bastion hosts.
  class Bastion
    class NotFoundError < RuntimeError; end

    # Initialize a new Bastion instance.
    #
    # @param project [String] The name of the project.
    # @param environment [String] The environment (e.g., staging, production).
    def initialize(project, environment)
      @project = project
      @environment = environment
    end

    # Lookup a running bastion instance.
    #
    # @return [Aws::EC2::Types::Instance] A running bastion instance.
    def lookup
      return @bastion if @bastion

      client = Aws::EC2::Client.new
      instances = client.describe_instances(filters: [
                                              { name: 'instance-state-name', values: ['running'] },
                                              { name: 'tag:project', values: [@project] },
                                              { name: 'tag:environment', values: [@environment] }
                                            ])

      raise NotFoundError, 'No running bastion found' unless instances.reservations.any?

      @bastion = instances.reservations.first.instances.first
    end

    # Open a tunnel to the bastion for remote port forwarding.
    #
    # @param port [Integer] The remote port to forward.
    # @param host [String] The remote host to forward to.
    # @param local_port [Integer] The local port to listen on.
    def tunnel(port, host, local_port = 9000)
      puts "Creating tunnel from https://localhost:#{local_port} to https://#{host}:#{port}"
      client = Aws::SSM::Client.new
      client.start_session({
                             target: lookup.instance_id,
                             document_name: 'AWS-StartPortForwardingSessionToRemoteHost',
                             reason: 'SessionReason',
                             parameters: {
                               portNumber: [port.to_s],
                               localPortNumber: [local_port.to_s],
                               host: [host]
                             }
                           })
    end
  end
end

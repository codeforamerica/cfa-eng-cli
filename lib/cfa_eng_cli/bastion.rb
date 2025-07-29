# frozen_string_literal: true

require 'aws-sdk-ec2'
require 'aws-sdk-ssm'

require_relative 'session_target'

module CfaEngCli
  # Manage and interact with bastion hosts.
  class Bastion
    class NotFoundError < RuntimeError; end

    # Initialize a new Bastion instance.
    #
    # @param profile [Config::Profile] Profile to use for the bastion.
    def initialize(profile)
      @profile = profile
    end

    # Lookup a running bastion instance.
    #
    # @return [Aws::EC2::Types::Instance] A running bastion instance.
    def lookup
      return @bastion if @bastion

      client = Aws::EC2::Client.new(profile: @profile.aws_profile)
      instances = client.describe_instances(filters: [
                                              { name: 'instance-state-name', values: ['running'] },
                                              { name: 'tag:project', values: [@profile.project] },
                                              { name: 'tag:environment', values: [@profile.environment] }
                                            ])

      raise NotFoundError, 'No running bastion found' unless instances.reservations.any?

      @bastion = instances.reservations.first.instances.first
    end

    # Create a target to connect to with session manager.
    #
    # @return [SessionTarget]
    def target
      client = Aws::EC2::Client.new(profile: @profile.aws_profile)
      SessionTarget.new(lookup.instance_id, client.config.region,
                        client.config.profile || ENV.fetch('AWS_PROFILE'))
    end

    # Open a tunnel to the bastion for remote port forwarding.
    #
    # @param port [Integer] The remote port to forward.
    # @param host [String] The remote host to forward to.
    # @param local_port [Integer] The local port to listen on.
    def tunnel(port, host, local_port = 9000)
      puts "Creating tunnel from https://localhost:#{local_port} to https://#{host}:#{port}"
      client = Aws::SSM::Client.new(profile: @profile.aws_profile)
      client.start_session(target: lookup.instance_id,
                           document_name: 'AWS-StartPortForwardingSessionToRemoteHost',
                           reason: "Remote port forwarding for #{host}",
                           parameters: {
                             portNumber: [port.to_s],
                             localPortNumber: [local_port.to_s],
                             host: [host]
                           })
    end
  end
end

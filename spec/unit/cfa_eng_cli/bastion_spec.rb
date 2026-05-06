# frozen_string_literal: true

require_relative '../../../lib/cfa_eng_cli/bastion'

RSpec.describe CfaEngCli::Bastion do
  subject(:bastion) { described_class.new(profile) }

  let(:config) { Struct.new(:region, :profile) }
  let(:ec2_client) { instance_double(Aws::EC2::Client, config: config.new('us-east-1')) }
  let(:instance) { instance_double(Aws::EC2::Types::Instance, instance_id: 'i-1234567890abcdef0') }

  let(:profile) do
    instance_double(CfaEngCli::Config::Profile, name: 'test-profile',
                                                project: 'test-project',
                                                environment: 'test-environment',
                                                aws_profile: 'test-aws-profile',
                                                region: 'us-east-1')
  end

  before do
    allow(Aws::EC2::Client).to receive(:new).and_return(ec2_client)
  end

  describe '#lookup' do
    let(:reservations) { [] }

    before do
      allow(ec2_client).to receive(:describe_instances).and_return(
        instance_double(Aws::EC2::Types::DescribeInstancesResult, reservations: reservations)
      )
    end

    context 'when running instances are found' do
      let(:reservations) do
        [
          instance_double(Aws::EC2::Types::Reservation, instances: [
                            instance,
                            instance_double(Aws::EC2::Types::Instance, instance_id: 'i-09876547321abcdef0')
                          ])
        ]
      end

      it 'returns the first running bastion instance when found' do
        expect(bastion.lookup.instance_id).to eq(instance.instance_id)
      end
    end

    context 'when no running instances are found' do
      it 'raises an exceptiuon' do
        expect { bastion.lookup }.to raise_error(CfaEngCli::Bastion::NotFoundError, 'No running bastion found')
      end
    end
  end

  describe '#target' do
    subject(:target) { bastion.target }

    before do
      ENV['AWS_PROFILE'] = 'rspec-environment'
      allow(ec2_client).to receive(:describe_instances).and_return(
        instance_double(Aws::EC2::Types::DescribeInstancesResult,
                        reservations: [instance_double(Aws::EC2::Types::Reservation, instances: [instance])])
      )
    end

    context 'when a profile is set on the client' do
      before do
        allow(ec2_client).to receive(:config).and_return(config.new('us-east-1', 'rspec-client'))
      end

      it 'uses the client profile' do
        expect(target.profile).to eq('rspec-client')
      end

      it 'sets the correct region' do
        expect(target.region).to eq('us-east-1')
      end

      it 'sets the correct id' do
        expect(target.id).to eq(instance.instance_id)
      end
    end

    context 'when a profile is not set on the client' do
      it 'uses the environment profile' do
        expect(target.profile).to eq('rspec-environment')
      end
    end
  end

  describe '#tunnel' do
    let(:ssm_client) { instance_double(Aws::SSM::Client) }

    before do
      allow(Aws::SSM::Client).to receive(:new).and_return(ssm_client)
      allow(ssm_client).to receive(:start_session)

      allow(Aws::EC2::Client).to receive(:new).and_return(ec2_client)
      allow(ec2_client).to receive(:describe_instances).and_return(
        instance_double(Aws::EC2::Types::DescribeInstancesResult,
                        reservations: [instance_double(Aws::EC2::Types::Reservation, instances: [instance])])
      )
    end

    it 'starts a port forwarding session with valid parameters' do
      bastion.tunnel(8080, 'example.com')

      expect(ssm_client).to have_received(:start_session).with(
        target: 'i-1234567890abcdef0',
        document_name: 'AWS-StartPortForwardingSessionToRemoteHost',
        reason: 'Remote port forwarding for example.com',
        parameters: {
          portNumber: ['8080'],
          localPortNumber: ['9000'],
          host: ['example.com']
        }
      )
    end

    it 'uses the specified local port when provided' do
      bastion.tunnel(8080, 'example.com', 3000)

      expect(ssm_client).to have_received(:start_session).with(
        target: 'i-1234567890abcdef0',
        document_name: 'AWS-StartPortForwardingSessionToRemoteHost',
        reason: 'Remote port forwarding for example.com',
        parameters: {
          portNumber: ['8080'],
          localPortNumber: ['3000'],
          host: ['example.com']
        }
      )
    end
  end
end

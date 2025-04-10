# frozen_string_literal: true

require 'aws-sdk-ssm'

require_relative '../../../lib/cfa_eng_cli/session_manager'
require_relative '../../../lib/cfa_eng_cli/session_target'

# We need to stub `exec` on the subject.
# rubocop:disable RSpec/SubjectStub
RSpec.describe CfaEngCli::SessionManager do
  subject(:manager) { described_class.new(session) }

  let(:session) do
    instance_double(
      Aws::SSM::Types::StartSessionResponse,
      session_id: 'session-123',
      stream_url: 'https://stream-url',
      token_value: 'token-abc'
    )
  end
  let(:target) do
    CfaEngCli::SessionTarget.new('i-1234567890abcdef0', 'us-east-1', 'rspec')
  end

  before do
    allow(manager).to receive(:exec)
  end

  describe '#open' do
    it 'executes session-manager-plugin with correct parameters' do
      manager.open(target)

      expect(manager).to have_received(:exec).with(
        'session-manager-plugin',
        {
          SessionId: 'session-123',
          StreamUrl: 'https://stream-url',
          TokenValue: 'token-abc'
        }.to_json,
        'us-east-1',
        'StartSession',
        'rspec',
        { Target: 'i-1234567890abcdef0' }.to_json,
        'https://ssm.us-east-1.amazonaws.com'
      )
    end
  end
end
# rubocop:enable RSpec/SubjectStub

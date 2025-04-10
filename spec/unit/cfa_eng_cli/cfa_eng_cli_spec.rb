# frozen_string_literal: true

require_relative '../../../lib/cfa_eng_cli/version'

RSpec.describe CfaEngCli do
  describe '#version' do
    it 'conforms to the semantic version format' do
      expect(described_class::VERSION).to match(/\d+\.\d+\.\d+/)
    end
  end
end

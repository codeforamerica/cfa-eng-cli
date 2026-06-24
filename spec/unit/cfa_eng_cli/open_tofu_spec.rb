# frozen_string_literal: true

require_relative '../../../lib/cfa_eng_cli/open_tofu'

RSpec.describe CfaEngCli::OpenTofu do
  let(:tofu) { described_class.new(environment, **init_opts) }

  let(:environment) { 'staging' }
  let(:init_opts) { {} }
  let(:doppler_secrets) do
    {
      'TF_VAR_ENVIRONMENT' => 'staging',
      'TF_VAR_PROJECT' => 'my-project',
      'TF_VAR_EMPTY' => '',
      'NOT_A_TF_VAR' => 'ignored',
      'DD_API_KEY' => 'dd-api-key-value',
      'DD_APP_KEY' => 'dd-app-key-value'
    }
  end

  before do
    stub_const('ENV', {})
    allow(tofu).to receive(:system)
    allow(tofu).to receive(:fetch_doppler_json).and_return(doppler_secrets.to_json)
    allow(Dir).to receive(:chdir).and_yield
  end

  describe '#initialize' do
    context 'without an explicit aws_profile in a non-production environment' do
      it 'sets AWS_PROFILE to the dev shared-services profile' do
        expect(ENV.fetch('AWS_PROFILE', nil)).to eq('shared-services-dev')
      end
    end

    context 'without an explicit aws_profile in the production environment' do
      let(:environment) { 'production' }

      it 'sets AWS_PROFILE to the prod shared-services profile' do
        expect(ENV.fetch('AWS_PROFILE', nil)).to eq('shared-services-prod')
      end
    end

    context 'with an explicit aws_profile' do
      let(:init_opts) { { aws_profile: 'custom-profile' } }

      it 'sets AWS_PROFILE to the given profile' do
        expect(ENV.fetch('AWS_PROFILE', nil)).to eq('custom-profile')
      end
    end
  end

  describe '#plan' do
    it 'changes to the config directory' do
      tofu.plan('foundation')

      expect(Dir).to have_received(:chdir).with('tofu/configs/foundation')
    end

    it 'runs tofu init' do
      tofu.plan('foundation')

      expect(tofu).to have_received(:system).with('tofu', 'init', '-reconfigure')
    end

    it 'runs tofu plan with -concise' do
      tofu.plan('foundation')

      expect(tofu).to have_received(:system).with('tofu', 'plan', '-concise')
    end

    context 'with extra args' do
      it 'appends extra args to tofu plan' do
        tofu.plan('foundation', args: ['-out', 'tfplan'])

        expect(tofu).to have_received(:system).with('tofu', 'plan', '-concise', '-out', 'tfplan')
      end
    end

    context 'with vars' do
      let(:vars) { ['-var', 'application=foo', '-var', 'region=us-east-1'] }

      it 'passes vars to tofu init' do
        tofu.plan('foundation', vars: vars)

        expect(tofu).to have_received(:system)
          .with('tofu', 'init', '-reconfigure', '-var', 'application=foo', '-var', 'region=us-east-1')
      end

      it 'passes vars to tofu plan' do
        tofu.plan('foundation', vars: vars)

        expect(tofu).to have_received(:system)
          .with('tofu', 'plan', '-concise', '-var', 'application=foo', '-var', 'region=us-east-1')
      end
    end
  end

  describe '#apply' do
    it 'changes to the config directory' do
      tofu.apply('application')

      expect(Dir).to have_received(:chdir).with('tofu/configs/application')
    end

    it 'runs tofu apply' do
      tofu.apply('application')

      expect(tofu).to have_received(:system).with('tofu', 'apply')
    end

    context 'with extra args' do
      it 'appends extra args to tofu apply' do
        tofu.apply('application', args: ['-auto-approve'])

        expect(tofu).to have_received(:system).with('tofu', 'apply', '-auto-approve')
      end
    end
  end

  describe '#destroy' do
    it 'changes to the config directory' do
      tofu.destroy('database')

      expect(Dir).to have_received(:chdir).with('tofu/configs/database')
    end

    it 'runs tofu destroy' do
      tofu.destroy('database')

      expect(tofu).to have_received(:system).with('tofu', 'destroy')
    end
  end

  describe '#output' do
    it 'changes to the config directory' do
      tofu.output('foundation')

      expect(Dir).to have_received(:chdir).with('tofu/configs/foundation')
    end

    it 'runs tofu output' do
      tofu.output('foundation')

      expect(tofu).to have_received(:system).with('tofu', 'output')
    end

    context 'with extra args' do
      it 'appends extra args to tofu output' do
        tofu.output('foundation', args: ['-json'])

        expect(tofu).to have_received(:system).with('tofu', 'output', '-json')
      end
    end

    it 'fetches Doppler variables' do
      tofu.output('foundation')

      expect(tofu).to have_received(:fetch_doppler_json)
    end

    context 'with vars' do
      let(:vars) { ['-var', 'application=canary-artifact'] }

      it 'passes vars to tofu init' do
        tofu.output('static-app', vars: vars)

        expect(tofu).to have_received(:system)
          .with('tofu', 'init', '-reconfigure', '-var', 'application=canary-artifact')
      end

      it 'passes vars to tofu output' do
        tofu.output('static-app', vars: vars)

        expect(tofu).to have_received(:system).with('tofu', 'output', '-var', 'application=canary-artifact')
      end
    end
  end

  describe '#force_unlock' do
    it 'changes to the config directory' do
      tofu.force_unlock('foundation', 'abc-123')

      expect(Dir).to have_received(:chdir).with('tofu/configs/foundation')
    end

    it 'runs tofu force-unlock with the lock ID' do
      tofu.force_unlock('foundation', 'abc-123')

      expect(tofu).to have_received(:system).with('tofu', 'force-unlock', 'abc-123')
    end

    it 'does not fetch Doppler variables' do
      tofu.force_unlock('foundation', 'abc-123')

      expect(tofu).not_to have_received(:fetch_doppler_json)
    end
  end

  describe '#bootstrap' do
    before do
      allow(tofu).to receive(:bucket_exists?)
      allow(FileUtils).to receive(:cp)
      allow(FileUtils).to receive(:rm)
    end

    it 'sets TF_VAR_environment' do
      tofu.bootstrap

      expect(ENV.fetch('TF_VAR_environment', nil)).to eq('staging')
    end

    it 'sets TF_VAR_project to the default' do
      tofu.bootstrap

      expect(ENV.fetch('TF_VAR_project', nil)).to eq('devops')
    end

    it 'accepts a custom project name' do
      tofu.bootstrap(project: 'my-project')

      expect(ENV.fetch('TF_VAR_project', nil)).to eq('my-project')
    end

    it 'checks for the S3 state bucket' do
      tofu.bootstrap(project: 'my-project')

      expect(tofu).to have_received(:bucket_exists?).with('my-project-staging-tfstate')
    end

    context 'when the bucket exists' do
      before { allow(tofu).to receive(:bucket_exists?).and_return(true) }

      it 'initializes with the remote backend' do
        tofu.bootstrap

        expect(tofu).to have_received(:system).with('tofu', 'init', '-input=false', '-reconfigure')
      end

      it 'does not copy the backend override file' do
        tofu.bootstrap

        expect(FileUtils).not_to have_received(:cp)
      end
    end

    context 'when the bucket does not exist' do
      before { allow(tofu).to receive(:bucket_exists?).and_return(false) }

      it 'copies the backend override file' do
        tofu.bootstrap

        expect(FileUtils).to have_received(:cp).with('overrides/backend_override.tf.local', 'backend_override.tf')
      end

      it 'initializes with the local backend' do
        tofu.bootstrap

        expect(tofu).to have_received(:system).with('tofu', 'init', '-input=false', '-reconfigure')
      end

      it 'applies the configuration' do
        tofu.bootstrap

        expect(tofu).to have_received(:system).with('tofu', 'apply', '-auto-approve', '-input=false')
      end

      it 'removes the backend override file' do
        tofu.bootstrap

        expect(FileUtils).to have_received(:rm).with('backend_override.tf')
      end

      it 'migrates state to the remote backend' do
        tofu.bootstrap

        expect(tofu).to have_received(:system).with('tofu', 'init', '-input=false', '-migrate-state', '-force-copy')
      end
    end

    context 'with vars when the bucket exists' do
      let(:vars) { ['-var', 'application=foo'] }

      before { allow(tofu).to receive(:bucket_exists?).and_return(true) }

      it 'passes vars to tofu init' do
        tofu.bootstrap(vars:)

        expect(tofu).to have_received(:system)
          .with('tofu', 'init', '-input=false', '-reconfigure', '-var', 'application=foo')
      end
    end

    context 'with vars when the bucket does not exist' do
      let(:vars) { ['-var', 'application=foo'] }

      before { allow(tofu).to receive(:bucket_exists?).and_return(false) }

      it 'passes vars to tofu init' do
        tofu.bootstrap(vars:)

        expect(tofu).to have_received(:system)
          .with('tofu', 'init', '-input=false', '-reconfigure', '-var', 'application=foo')
      end

      it 'passes vars to tofu apply' do
        tofu.bootstrap(vars:)

        expect(tofu).to have_received(:system)
          .with('tofu', 'apply', '-auto-approve', '-input=false', '-var', 'application=foo')
      end
    end
  end

  describe 'Doppler variable fetching' do
    before { tofu.plan('foundation') }

    it 'sets DOPPLER_PROJECT to the default' do
      expect(ENV.fetch('DOPPLER_PROJECT', nil)).to eq('shared-services')
    end

    it 'sets DOPPLER_CONFIG for staging' do
      expect(ENV.fetch('DOPPLER_CONFIG', nil)).to eq('infra_staging')
    end

    it 'sets TF_VAR_environment from Doppler secrets' do
      expect(ENV.fetch('TF_VAR_environment', nil)).to eq('staging')
    end

    it 'sets TF_VAR_project from Doppler secrets' do
      expect(ENV.fetch('TF_VAR_project', nil)).to eq('my-project')
    end

    it 'skips Doppler variables with empty values' do
      expect(ENV).not_to have_key('TF_VAR_empty')
    end

    it 'skips Doppler variables that do not start with TF_VAR_ and are not in ADDITIONAL_SECRETS' do
      expect(ENV).not_to have_key('NOT_A_TF_VAR')
    end

    it 'sets DD_API_KEY from Doppler secrets' do
      expect(ENV.fetch('DD_API_KEY', nil)).to eq('dd-api-key-value')
    end

    it 'sets DD_APP_KEY from Doppler secrets' do
      expect(ENV.fetch('DD_APP_KEY', nil)).to eq('dd-app-key-value')
    end

    context 'with a custom doppler_project' do
      let(:init_opts) { { doppler_project: 'my-doppler-project' } }

      it 'sets DOPPLER_PROJECT to the given project' do
        expect(ENV.fetch('DOPPLER_PROJECT', nil)).to eq('my-doppler-project')
      end
    end

    context 'with a custom doppler_environment' do
      let(:init_opts) { { doppler_environment: 'platform' } }

      it 'sets DOPPLER_CONFIG using the custom environment prefix' do
        expect(ENV.fetch('DOPPLER_CONFIG', nil)).to eq('platform_staging')
      end
    end

    context 'with a custom doppler_environment and environment=production' do
      let(:environment) { 'production' }
      let(:init_opts) { { doppler_environment: 'platform' } }

      it 'sets DOPPLER_CONFIG to <env>_prod' do
        expect(ENV.fetch('DOPPLER_CONFIG', nil)).to eq('platform_prod')
      end
    end

    context 'with environment=development' do
      let(:environment) { 'development' }

      it 'sets DOPPLER_CONFIG to infra_dev' do
        expect(ENV.fetch('DOPPLER_CONFIG', nil)).to eq('infra_dev')
      end
    end

    context 'with environment=production' do
      let(:environment) { 'production' }

      it 'sets DOPPLER_CONFIG to infra_prod' do
        expect(ENV.fetch('DOPPLER_CONFIG', nil)).to eq('infra_prod')
      end
    end

    context 'when existing TF_VAR_* vars are set before fetching' do
      before do
        ENV['TF_VAR_stale'] = 'old-value'
        tofu.plan('foundation')
      end

      it 'clears the stale variable' do
        expect(ENV).not_to have_key('TF_VAR_stale')
      end
    end
  end
end

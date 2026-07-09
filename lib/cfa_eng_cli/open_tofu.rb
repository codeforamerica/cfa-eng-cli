# frozen_string_literal: true

require 'fileutils'
require 'json'

module CfaEngCli
  # Runs OpenTofu commands with Doppler secrets and environment-aware AWS profile selection.
  class OpenTofu
    ADDITIONAL_SECRETS = %w[DD_API_KEY DD_APP_KEY].freeze
    def initialize(environment, aws_profile: nil, region: nil, doppler_project: 'shared-services',
                   doppler_environment: 'infra')
      @environment = environment
      @doppler_project = doppler_project
      @doppler_environment = doppler_environment
      ENV['AWS_PROFILE'] = aws_profile || default_aws_profile
      ENV['AWS_REGION'] = region if region
    end

    # Runs tofu init in the given config directory.
    #
    # @param config [String] Config layer name.
    # @param args [Array<String>] Extra arguments to pass to tofu init.
    # @param vars [Array<String>] Pre-formatted -var arguments.
    def init(config, args: [], vars: [])
      fetch_doppler_variables
      run_tofu(config, nil, args, var_args: vars)
    end

    # Runs tofu plan in the given config directory.
    #
    # @param config [String] Config layer name.
    # @param args [Array<String>] Extra arguments to pass to tofu plan.
    # @param vars [Array<String>] Pre-formatted -var arguments.
    def plan(config, args: [], vars: [])
      fetch_doppler_variables
      run_tofu(config, 'plan', ['-concise'] + args, var_args: vars)
    end

    # Runs tofu apply in the given config directory.
    #
    # @param config [String] Config layer name (e.g. "foundation").
    # @param args [Array<String>] Extra arguments to pass to tofu apply.
    # @param vars [Array<String>] Pre-formatted -var arguments.
    def apply(config, args: [], vars: [])
      fetch_doppler_variables
      run_tofu(config, 'apply', args, var_args: vars)
    end

    # Runs tofu destroy in the given config directory.
    #
    # @param config [String] Config layer name (e.g. "foundation").
    # @param args [Array<String>] Extra arguments to pass to tofu destroy.
    # @param vars [Array<String>] Pre-formatted -var arguments.
    def destroy(config, args: [], vars: [])
      fetch_doppler_variables
      run_tofu(config, 'destroy', args, var_args: vars)
    end

    # Runs tofu output in the given config directory.
    #
    # @param config [String] Config layer name (e.g. "foundation").
    # @param args [Array<String>] Extra arguments to pass to tofu output.
    # @param vars [Array<String>] Pre-formatted -var arguments.
    def output(config, args: [], vars: [])
      fetch_doppler_variables
      run_tofu(config, 'output', args, var_args: vars)
    end

    # Force-unlocks the state for the given config directory.
    #
    # @param config [String] Config layer name (e.g. "foundation").
    # @param lock_id [String] Lock ID to release.
    # @param vars [Array<String>] Pre-formatted -var arguments.
    def force_unlock(config, lock_id, vars: [])
      fetch_doppler_variables
      run_tofu(config, 'force-unlock', [lock_id], var_args: vars)
    end

    # Bootstraps the remote backend for the environment.
    #
    # If the S3 state bucket already exists, initializes with the remote backend.
    # Otherwise, performs a full local-to-remote migration.
    #
    # @param project [String] Project name used to construct the S3 bucket name.
    # @param vars [Array<String>] Pre-formatted -var arguments.
    def bootstrap(project: 'devops', vars: [])
      fetch_doppler_variables
      ENV['TF_VAR_environment'] = @environment
      ENV['TF_VAR_project'] = project
      bucket = "#{project}-#{@environment}-tfstate"
      puts "Checking if backend bucket exists: #{bucket}"
      Dir.chdir('tofu/configs/foundation') do
        bucket_exists?(bucket) ? init_remote_backend(vars) : bootstrap_remote_backend(bucket, vars)
      end
    end

    private

    # Returns the default AWS profile for the current environment.
    #
    # @return [String]
    def default_aws_profile
      @environment == 'production' ? 'shared-services-prod' : 'shared-services-dev'
    end

    # Fetches secrets from Doppler and exports them as TF_VAR_* environment variables.
    def fetch_doppler_variables
      ENV['DOPPLER_PROJECT'] = @doppler_project
      ENV['DOPPLER_CONFIG'] = doppler_config
      ENV.select { |k, _| k.start_with?('TF_VAR_') }.each_key { |k| ENV.delete(k) }
      JSON.parse(fetch_doppler_json).each { |name, value| set_doppler_variable(name, value) }
    end

    # Sets a single Doppler secret as a lowercase TF_VAR_* env var if applicable.
    #
    # @param name [String] Doppler secret name (must start with TF_VAR_).
    # @param value [String, nil] Secret value (skipped if blank).
    def set_doppler_variable(name, value)
      return if value.nil? || value.empty?

      if name.start_with?('TF_VAR_')
        lower_name = "TF_VAR_#{name[7..].downcase}"
        puts "Setting #{lower_name}"
        ENV[lower_name] = value
      elsif ADDITIONAL_SECRETS.include?(name)
        puts "Setting #{name}"
        ENV[name] = value
      end
    end

    # Shells out to Doppler to download secrets as JSON.
    #
    # @return [String] JSON string of secrets.
    def fetch_doppler_json
      `doppler secrets download --no-file --format json`
    end

    # Returns the Doppler config name for the current environment.
    #
    # @return [String]
    def doppler_config
      suffix = { 'development' => 'dev', 'production' => 'prod' }.fetch(@environment, @environment)
      "#{@doppler_environment}_#{suffix}"
    end

    # Runs tofu init followed by the given command in the config directory.
    # Both init and the subcommand receive the same var_args.
    #
    # @param config [String] Layer name under tofu/configs/.
    # @param command [String, nil] tofu subcommand (plan, apply, destroy, etc.).
    #   When nil, only tofu init is run and extra_args are passed to it.
    # @param extra_args [Array<String>] Extra arguments passed to the subcommand,
    #   or to tofu init when command is nil.
    # @param var_args [Array<String>] Pre-formatted -var arguments passed to both init and the subcommand.
    def run_tofu(config, command, extra_args, var_args: [])
      Dir.chdir("tofu/configs/#{config}") do
        system('tofu', 'init', '-reconfigure', *(command ? var_args : extra_args + var_args))
        system('tofu', command, *extra_args, *var_args) if command
      end
    end

    # Returns true if the S3 state bucket exists.
    #
    # @param bucket [String] Bucket name to check.
    # @return [Boolean]
    def bucket_exists?(bucket)
      system('aws', 's3api', 'head-bucket', '--no-cli-pager',
             '--bucket', bucket, '--region', ENV.fetch('AWS_REGION', 'us-east-1'),
             out: File::NULL, err: File::NULL)
    end

    # Initializes tofu with the remote backend when the state bucket already exists.
    #
    # @param var_args [Array<String>] Pre-formatted -var arguments.
    def init_remote_backend(var_args)
      puts 'Backend bucket exists. Initializing with remote backend...'
      tofu!('init', '-input=false', '-migrate-state', '-force-copy', *var_args)
    end

    # Performs the full local-to-remote backend migration for a new environment.
    #
    # Each step must succeed before the next runs; a failure aborts before the
    # state migration to avoid copying a partial local state over the remote
    # backend. The local backend override is always removed on the way out.
    #
    # @param bucket [String] Bucket name (used only for logging).
    # @param var_args [Array<String>] Pre-formatted -var arguments.
    def bootstrap_remote_backend(bucket, var_args)
      puts "Backend bucket #{bucket} does not exist. Bootstrapping with local backend..."
      FileUtils.cp('overrides/backend_override.tf.local', 'backend_override.tf')
      tofu!('init', '-input=false', '-reconfigure', *var_args)
      tofu!('apply', '-auto-approve', '-input=false', *var_args)
      FileUtils.rm('backend_override.tf')
      tofu!('init', '-input=false', '-migrate-state', '-force-copy', *var_args)
      puts 'Bootstrap complete. Remote backend configured.'
    ensure
      FileUtils.rm_f('backend_override.tf')
    end

    # Runs a tofu command, aborting the process if it fails.
    #
    # @param args [Array<String>] Arguments to pass to tofu.
    def tofu!(*args)
      system('tofu', *args) || abort("Error: `tofu #{args.first}` failed; aborting bootstrap.")
    end
  end
end

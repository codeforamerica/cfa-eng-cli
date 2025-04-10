# frozen_string_literal: true

require_relative 'lib/cfa_eng_cli/version'

Gem::Specification.new do |s|
  s.name        = 'cfa-eng-cli'
  s.version     = CfaEngCli::VERSION
  s.licenses    = ['MIT']
  s.summary     = 'Code for America Engineering CLI'
  s.description = 'A CLI tool for Code for America engineering teams.'
  s.authors     = ['Code for America']
  s.email       = 'infra@codeforamerica.org'
  s.files       = Dir['lib/**/*'] + Dir['Gemfile*'] + ['Rakefile']
  s.homepage    = 'https://codeforamerica.org'
  s.metadata    = {
    'bug_tracker_uri' => 'https://github.com/codeforamerica/cfa-eng-url/issues',
    'homepage_uri' => s.homepage,
    # Require privileged gem operations (such as publishing) to use MFA.
    'rubygems_mfa_required' => 'true',
    'source_code_uri' => 'https://github.com/codeforamerica/cfa-eng-url'
  }

  s.required_ruby_version = '>= 3.3'

  s.add_dependency 'aws-sdk-ec2', '~> 1.515'
  s.add_dependency 'aws-sdk-ssm', '~> 1.192'
  s.add_dependency 'configsl', '~> 1.0'
  s.add_dependency 'libxml-ruby', '~> 5.0'
  s.add_dependency 'thor', '~> 1.3'
end

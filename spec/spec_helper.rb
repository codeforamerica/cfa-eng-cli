# frozen_string_literal: true

# Configure code coverage reporting.
if ENV.fetch('COVERAGE', false)
  require 'simplecov'

  SimpleCov.minimum_coverage 90
  SimpleCov.start do
    add_filter '/spec/'
    # Exclude commands, since they should make use of common code.
    add_filter '/lib/cfa_eng_cli/commands/'

    track_files 'lib/**/*.rb'
  end
end

require_relative '../lib/cfa-eng-cli'

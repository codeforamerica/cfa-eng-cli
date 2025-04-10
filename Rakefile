# frozen_string_literal: true

require 'bundler'
require 'rubocop/rake_task'
require 'rspec/core/rake_task'

task default: %i[rubocop spec]

Bundler::GemHelper.install_tasks

RuboCop::RakeTask.new(:rubocop) do |task|
  task.requires << 'rubocop'
  task.formatters = %w[pacman]
  task.formatters << 'github' if ENV.fetch('GITHUB_ACTIONS', false)
end

RSpec::Core::RakeTask.new(:spec)

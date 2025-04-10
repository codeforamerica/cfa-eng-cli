# frozen_string_literal: true

require 'bundler'
require 'rubocop/rake_task'

task default: %i[rubocop]

Bundler::GemHelper.install_tasks

RuboCop::RakeTask.new(:rubocop) do |task|
  task.requires << 'rubocop'
  task.formatters = %w[pacman]
  task.formatters << 'github' if ENV.fetch('GITHUB_ACTIONS', false)
end

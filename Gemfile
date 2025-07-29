# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# TODO: Move to gemspec once a new release has been cut.
gem 'configsl', git: 'https://github.com/jamesiarmes/configsl.git', branch: 'collections'

group :development do
  gem 'rake', '~> 13.2'
  gem 'rubocop', '~> 1.75'
  gem 'rubocop-md', '~> 2.0'
  gem 'rubocop-rake', '~> 0.7'
  gem 'rubocop-rspec', '~> 3.5'
  gem 'rubocop-yard', '~> 0.10'
end

group :test do
  gem 'rspec', '~> 3.13'
  gem 'rspec-github', '~> 3.0'
  gem 'simplecov', '~> 0.22'
end

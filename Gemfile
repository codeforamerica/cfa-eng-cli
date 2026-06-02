# frozen_string_literal: true

source 'https://rubygems.org'

gemspec

# TODO: Move to gemspec once a new release has been cut.
gem 'configsl', git: 'https://github.com/jamesiarmes/configsl.git', branch: 'collections'

group :development do
  gem 'rake', '~> 13.4'
  gem 'rubocop', '~> 1.87'
  gem 'rubocop-md', '~> 2.0'
  gem 'rubocop-performance', '~> 1.26'
  gem 'rubocop-rake', '~> 0.7'
  gem 'rubocop-rspec', '~> 3.9'
  gem 'rubocop-yard', '~> 1.2'
  gem 'ruby-lsp', '~> 0.26'
  gem 'ruby-lsp-rspec', '~> 0.1'
end

group :test do
  gem 'rspec', '~> 3.13'
  gem 'rspec-github', '~> 3.0'
  gem 'simplecov', '~> 0.22'
end

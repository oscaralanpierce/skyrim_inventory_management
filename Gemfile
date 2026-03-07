# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) {|repo| "https://github.com/#{repo}.git" }

ruby '4.0.1'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails', branch: 'main'
gem 'rails', '7.2.3'

# Use postgresql as the database for Active Record
gem 'pg', '~> 1.5'

# Use Puma as the app server
gem 'puma', '~> 7.1.0'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '~> 1.18', require: false

# Use Rack CORS for handling Cross-Origin Resource Sharing (CORS), making cross-origin AJAX possible
gem 'rack-cors', '~> 3.0.0'

# Use Faraday to validate Google auth access tokens
gem 'faraday', '~> 2.14.1'

# Use the CSV gem, which is no longer included in the standard library, to parse CSVs
gem 'csv', '~> 3.3'

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', '~> 13.0', platforms: %i[mri windows]

  # Use RSpec for unit and integration testing
  gem 'rspec-rails', '~> 8.0'

  # Use Timecop to freeze time in tests (for testing timestamps, etc.)
  gem 'timecop', '~> 0.9.10'

  # Use DatabaseCleaner to clear the database between specs
  gem 'database_cleaner-active_record', '~> 2.2'

  # Use FactoryBot to create models for tests
  gem 'factory_bot_rails', '~> 6.4.4'

  # Use Rubocop to enforce style guide
  gem 'rubocop-rails', '~> 2.34', require: false

  # Use Rubocop to enforce RSpec styles
  gem 'rubocop-rspec', '~> 3.9', require: false

  # Use Rubocop to enforce performance standards
  gem 'rubocop-performance', '~> 1.23', require: false

  # Use Rubocop to lint factories
  gem 'rubocop-factory_bot', '~> 2.27', require: false

  # Use WebMock to mock HTTP requests, mainly for auth purposes
  gem 'webmock', '~> 3.24'
end

group :development do
  # Use listen to hot-reload app code
  gem 'listen', '~> 3.9'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring', '~> 4.4'
end

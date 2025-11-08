source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read(".ruby-version")

gem "bootsnap", require: false
gem "dotenv-rails", require: "dotenv/load"
gem "pg"
gem "puma"
gem "rails", "~> 8.0.3"

gem "okcomputer"
gem "propshaft"
gem "sentry-rails"
gem "sentry-ruby"

gem "rack-canonical-host"

# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"

# Tailwind CSS for Rails [https://github.com/rails/tailwindcss-rails]
gem "tailwindcss-rails"

# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"

# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"
# Bundle and transpile JavaScript with esbuild [https://github.com/rails/jsbundling-rails]
gem "jsbundling-rails"

# Use Redis adapter to run Action Cable in production
# gem "redis"

# Use Kredis to get higher-level data types in Redis [https://github.com/rails/kredis]
# gem "kredis"

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
gem "image_processing", "~> 1.2"

# S3-compatible storage (iDrive e2)
gem "aws-sdk-s3", require: false

# Protect against accidentally slow migrations
gem "strong_migrations"

group :development do
  # code annotation
  gem "annotaterb", require: false
  gem "chusaku", require: false

  gem "letter_opener"

  # Use console on exceptions pages [https://github.com/rails/web-console]
  gem "web-console"

  # Add speed badges [https://github.com/MiniProfiler/rack-mini-profiler]
  # gem "rack-mini-profiler"

  gem "brakeman", require: false
  gem "overcommit", require: false
  gem "rubocop", require: false
  gem "rubocop-capybara", require: false
  gem "rubocop-factory_bot", require: false
  gem "rubocop-performance", require: false
  gem "rubocop-rails", require: false
  gem "rubocop-rspec", require: false
  gem "rubocop-rspec_rails", require: false
end

group :development, :test do
  gem "bullet"
  gem "factory_bot_rails"
  gem "faker"
  gem "pry-byebug"
  gem "pry-rails"
  gem "rspec-rails"

  # ERB linting. Run via `bundle exec erb_lint .`
  gem "erb_lint", require: false
end

group :test do
  # Use system testing [https://guides.rubyonrails.org/testing.html#system-testing]
  gem "capybara"
  gem "selenium-webdriver"

  gem "axe-matchers"
  gem "lighthouse-matchers"
  gem "simplecov", require: false

  # HTTP mocking and testing
  gem "vcr"
  gem "webmock"

  # Time manipulation for time-based tests
  gem "timecop"

  # Cleaner test matchers
  gem "shoulda-matchers"
end
gem "pundit"

gem "devise", "~> 4.9"

gem "httparty"

gem "kaminari"

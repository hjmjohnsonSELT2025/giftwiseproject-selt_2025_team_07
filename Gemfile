source "https://rubygems.org"

ruby "3.3.8"

# Core Rails
gem "rails", "~> 7.1.6"

# Asset pipeline
gem "sprockets-rails"

# Web server
gem "puma", ">= 5.0"

# Import maps / JS
gem "importmap-rails"

# Hotwire
gem "turbo-rails"
gem "stimulus-rails"

# JSON APIs
gem "jbuilder"

# Timezone data for Windows/JRuby
gem "tzinfo-data", platforms: %i[windows jruby]

# Boot speed
gem "bootsnap", require: false

# Tailwind CSS
gem "tailwindcss-rails", "~> 4.4"

# Authentication helpers
gem "bcrypt", "~> 3.1.7"

# -------------------------
# Environments
# -------------------------

group :development, :test do
  # SQLite locally (dev & test only)
  gem "sqlite3", ">= 1.4"

  # Debugging
  gem "debug", platforms: %i[mri windows]

  # RSpec test framework
  gem "rspec-rails", "~> 7.1"

  # FactoryBot for test data
  gem "factory_bot_rails", "~> 6.4"

  # Cucumber (BDD) + Capybara
  gem "cucumber-rails", "~> 2.6", require: false
  gem "capybara", "~> 3.40"

  # For JS-enabled feature specs
  gem "selenium-webdriver", "~> 4.0"
  gem "webdrivers", "~> 5.0"

  # Cleaning DB between tests
  gem "database_cleaner-active_record", "~> 2.0"
end


group :development do
  # Console on exception pages
  gem "web-console"
end

group :test do
  gem "shoulda-matchers", "~> 6.0"
  gem "rails-controller-testing"
  gem "simplecov", require: false
end

group :production do
  # Heroku Postgres
  gem "pg", "~> 1.5"
end
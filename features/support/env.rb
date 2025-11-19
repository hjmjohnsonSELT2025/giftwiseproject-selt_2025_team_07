require 'cucumber/rails'
require 'capybara/cucumber'

ActionController::Base.allow_rescue = false

begin
  DatabaseCleaner.strategy = :transaction
rescue NameError
  raise "You need to add database_cleaner to your Gemfile (in the :test group) if you wish to use it."
end

Cucumber::Rails::Database.javascript_strategy = :truncation

OmniAuth.config.test_mode = true

Capybara.register_driver :selenium do |app|
  Capybara::Selenium::Driver.new(app, browser: :chrome)
end

Capybara.default_driver = :rack_test
Capybara.javascript_driver = :selenium

Before do
  OmniAuth.config.test_mode = true
  OmniAuth.config.mock_auth[:google_oauth2] = nil
end

After do
  OmniAuth.config.mock_auth[:google_oauth2] = nil
end
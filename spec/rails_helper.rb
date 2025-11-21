require 'spec_helper'

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'shoulda/matchers'
require 'factory_bot_rails'

Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }
# Load support files AFTER Rails is loaded
Dir[Rails.root.join("spec/support/**/*.rb")].each { |f| require f }

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

Rails.application.routes.default_url_options[:host] = 'localhost:3000'

RSpec.configure do |config|
  config.include RequestAuthenticationHelper, type: :request
  config.fixture_paths = [Rails.root.join('spec/fixtures')]
  config.use_transactional_fixtures = true

  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods
  config.include Rails.application.routes.url_helpers, type: :controller

  config.include OmniauthHelpers, type: :controller
  config.include OmniauthHelpers, type: :feature
  config.include OmniauthHelpers, type: :request

  config.before(:each) do
    OmniAuth.config.test_mode = false
    ActionMailer::Base.deliveries.clear
  end
  config.before(:each) do
    allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("test"))
  end

  config.after(:each) do
    OmniAuth.config.mock_auth[:google_oauth2] = nil
  end
end

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end

# This file is copied to spec/ when you run 'rails generate rspec:install'
require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
ENV["PARALLEL_TEST_FIRST_IS_1"] = "true" # number parallel databases correctly
require_relative "../config/environment"
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
# Add additional requires below this line. Rails is not loaded until this point!
require "sidekiq/testing"
require "vcr"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.allow_http_connections_when_no_cassette = false
  config.hook_into :webmock
  config.ignore_localhost = true # Turn off for local tests, e.g. feature

  %w[STRAVA_SECRET STRAVA_CLIENT_ID].each do |key|
    config.filter_sensitive_data("<#{key}>") { ENV[key] }
  end

  config.before_record do |i|
    i.response.headers.delete("Set-Cookie")
    i.request.headers.delete("Authorization")
    i.request.headers.delete("x-api-key")
  end
end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
Rails.root.glob("spec/support/**/*.rb").sort.each { |f| require f }

# Include capybara for view component system specs
require "capybara/rails"
require "capybara/rspec"
Capybara.register_driver :chrome_headless do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  args = %w[
    --headless --window-size=1920,1080 --no-sandbox
    --disable-sync --disable-extensions --disable-logging
    --disable-background-networking --disable-component-update
    --disable-client-side-phishing-detection
  ]
  args.each { |arg| options.add_argument(arg) }
  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end
# Configure Capybara
Capybara.configure do |config|
  config.default_driver = :chrome_headless
  config.javascript_driver = :chrome_headless
end
require "view_component/test_helpers"
require "view_component/system_test_helpers"

# Checks for pending migrations and applies them before tests are run.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [Rails.root.join("spec/fixtures")]

  config.include Devise::Test::IntegrationHelpers, type: :request
  # Our stuff
  config.include RequestSpecHelpers, type: :request

  # View components
  config.include ViewComponent::TestHelpers, type: :component
  config.include ViewComponent::SystemTestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component
  config.before(:each, :js, type: :system) { driven_by(:selenium_chrome_headless) }

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  config.render_views = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails can automatically mix in different behaviours to your tests
  # based on their file location, for example enabling you to call `get` and
  # `post` in specs under `spec/controllers`.
  #
  # You can disable this behaviour by removing the line below, and instead
  # explicitly tag your specs with their type, e.g.:
  #
  #     RSpec.describe UsersController, type: :controller do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/6-0/rspec-rails
  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end

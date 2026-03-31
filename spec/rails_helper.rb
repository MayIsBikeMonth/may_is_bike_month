require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
ENV["PARALLEL_TEST_FIRST_IS_1"] = "true" # number parallel databases correctly
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "sidekiq/testing"

require "vcr"
require "view_component/test_helpers"
require "view_component/system_test_helpers"
require "capybara/rspec"

VCR.configure do |config|
  config.cassette_library_dir = "spec/vcr_cassettes"
  config.allow_http_connections_when_no_cassette = false
  config.hook_into :webmock
  config.ignore_localhost = true

  %w[STRAVA_SECRET STRAVA_CLIENT_ID].each do |key|
    config.filter_sensitive_data("<#{key}>") { ENV[key] }
  end

  config.before_record do |i|
    i.response.headers.delete("Set-Cookie")
    i.request.headers.delete("Authorization")
    i.request.headers.delete("x-api-key")
  end
end

Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

# Include capybara for view component system specs
require "capybara/rails"
Capybara.register_driver :chrome_headless do |app|
  # Add a bunch of options to prevent chrome from calling home
  # (calling home breaks on copilot, because of the firewall, and raises errors)
  options = Selenium::WebDriver::Chrome::Options.new
  args = %w[
    --headless --window-size=1920,1080 --no-sandbox
    --disable-sync --disable-extensions --disable-logging
    --disable-background-networking --disable-component-update
    --disable-client-side-phishing-detection --disable-default-apps
    --disable-translate --disable-background-timer-throttling
    --disable-backgrounding-occluded-windows --disable-features=TranslateUI
    --disable-ipc-flooding-protection --no-first-run
    --disable-gpu --disable-dev-shm-usage --disable-setuid-sandbox
    --disable-web-security --no-zygote --single-process
    --disable-features=VizDisplayCompositor --disable-breakpad
    --disable-crash-reporter --disable-crash-dump --disable-notifications
    --mute-audio --no-default-browser-check --no-pings
    --disable-domain-reliability --disable-features=AutofillServerCommunication
  ]
  args.each { |arg| options.add_argument(arg) }
  Capybara::Selenium::Driver.new(app, browser: :chrome, options:)
end
# Configure Capybara
Capybara.configure do |config|
  config.default_driver = :chrome_headless
  config.javascript_driver = :chrome_headless
end

begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include RequestSpecHelpers, type: :request
  config.include FactoryBot::Syntax::Methods

  # View component test helpers
  config.include ViewComponent::TestHelpers, type: :component
  config.include ViewComponent::SystemTestHelpers, type: :component
  config.include Capybara::RSpecMatchers, type: :component

  config.use_transactional_fixtures = true
  config.render_views = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end

# retry flaky specs on CI
if ENV["RETRY_FLAKY"]
  require "rspec/retry"

  RSpec.configure do |config|
    config.verbose_retry = true

    config.around(:each) do |ex|
      if ex.metadata[:flaky]
        ex.run_with_retry retry: 2
      else
        ex.run
      end
    end
  end
end

# Override capybara methods to support tailwind selectors
# Original methods defined in 'lib/capybara/rspec/matchers.rb'
#
# This is necessary because colons need to be escaped for these matchers (i.e. tw\:p-6)
#
module Capybara
  module RSpecMatchers
    def have_selector(*args, **, &)
      args = args.map { |a| a.is_a?(String) ? escape_colon_classes(a) : a }
      Matchers::HaveSelector.new(*args, **, &)
    end

    def have_css(expr, **, &)
      Matchers::HaveSelector.new(:css, escape_colon_classes(expr), **, &)
    end

    private

    # Automatically escape colons in tailwind class selectors (e.g. .tw\:p-6)
    # Only escapes colons that appear within class selectors, preserving
    # pseudo-selectors like :hover, :focus, :disabled, :not(), etc.
    def escape_colon_classes(expr)
      expr.gsub(/(\.\w+):/) { "#{$1}\\:" }
    end
  end
end

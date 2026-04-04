source "https://rubygems.org"

gem "rails", "~> 8.1.2"
gem "pg", "~> 1.1" # Use postgresql as the database for Active Record
gem "redis" # Redis itself
gem "sidekiq" # Background job processing (with redis)

# Server
gem "puma" # Use the Puma web server
gem "thruster", require: false # Asset compression and caching for Puma
gem "kamal", require: false # Deploy with Kamal
gem "rack-cors" # Make cors requests

# Make logging - more useful and ingestible
gem "lograge" # Structure log data, put it in single lines to improve the functionality
gem "logstash-event" # Use logstash format for logging data

# Frontend stuff
gem "propshaft" # The modern asset pipeline for Rails
gem "importmap-rails" # Use JavaScript with ESM import maps
gem "turbo-rails" # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "stimulus-rails" # Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "tailwindcss-rails" # Tailwind for css
gem "view_component" # view components!
gem "lookbook" # view_component rendering
gem "pagy" # pagination
gem "chartkick" # Display charts
gem "groupdate" # Required for charts

# Users
gem "devise"
gem "multi_json" # Required by omniauth-strava
gem "omniauth-strava"
gem "omniauth-rails_csrf_protection"
gem "faraday" # Used to make bare requests to strava

# File storage
gem "image_processing", "~> 1.2" # Use Active Storage variants

# Functionality extensions
gem "cgi" # Required for Ruby 4.0+ (removed from stdlib)
gem "tzinfo-data", platforms: %i[windows jruby] # Windows does not include zoneinfo files, so bundle the tzinfo-data gem

# Error tracking
gem "honeybadger" # Exception and uptime monitoring

# Performance
gem "fast_blank" # high performance replacement String#blank?
gem "flamegraph", require: false
gem "stackprof", require: false # Required by flamegraph
gem "rack-mini-profiler", require: false # If you can't see it you can't make it better
gem "bootsnap", require: false # Reduces boot times through caching; required in config/boot.rb

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "foreman" # Process runner for local work
  gem "dotenv-rails" # Add environmental variables for importing things
  gem "rspec-rails" # Test framework
  gem "factory_bot_rails" # mocking/stubbing
  gem "standard", ">= 1.41", require: false # Ruby linter
  gem "htmlbeautifier" # html linting
  gem "bundler-audit", require: false # Audits gems for known security defects
  gem "brakeman", require: false # Security vulnerabilities
end

group :development do
  gem "web-console" # Use console on exceptions pages
  gem "letter_opener" # Preview emails in the browser
  gem "bullet" # N+1 query detection
  gem "annotaterb" # Annotate models with schema info
  gem "listen", ">= 3.0.5", "< 3.11"
  gem "rerun" # For restarting sidekiq on file changes
  gem "hotwire-livereload" # Livereload!
end

group :test do
  gem "guard", require: false
  gem "guard-rspec", require: false
  gem "rb-readline", require: false
  gem "vcr" # Stub external HTTP requests
  gem "webmock" # mocking for VCR
  gem "capybara" # For view components
  gem "selenium-webdriver" # Browser driver for system specs
  gem "rails-controller-testing" # Assert testing views
  gem "rspec-retry", require: false # Retry flaky test failures on CI
  gem "axe-core-rspec" # Accessibility testing
end

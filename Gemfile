source "https://rubygems.org"

ruby "3.2.3"

# Bundle edge Rails instead: gem "rails", github: "rails/rails", branch: "main"
gem "rails", "~> 7.1.3", ">= 7.1.3.1"
gem "puma" # Use Puma as the app server
gem "rack-cors" # Make cors requests

gem "pg" # database

# Redis, redis requirements
gem "redis" # Redis itself
gem "sidekiq" # Background job processing (with redis)
gem "sinatra" # Used for sidekiq web
gem "sidekiq-failures" # Show sidekiq failures

# Frontend stuff
# The original asset pipeline for Rails [https://github.com/rails/sprockets-rails]
gem "sprockets-rails"
# Use JavaScript with ESM import maps [https://github.com/rails/importmap-rails]
gem "importmap-rails"
# Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
gem "turbo-rails"
# Hotwire's modest JavaScript framework [https://stimulus.hotwired.dev]
gem "stimulus-rails"

# Make logging - more useful and ingestible
gem "lograge" # Structure log data, put it in single lines to improve the functionality
gem "logstash-event" # Use logstash format for logging data

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem "tzinfo-data", platforms: %i[ windows jruby ]

# Use Active Storage variants [https://guides.rubyonrails.org/active_storage_overview.html#transforming-images]
# gem "image_processing", "~> 1.2"

group :production, :staging do
  gem "honeybadger" # Error reporting
  # gem "skylight" # Performance, add when needed
end

group :development, :test do
  gem "foreman" # Process runner for local work
  gem "dotenv-rails" # Add environmental variables for importing things
  gem "rspec-rails" # Test framework
  gem "factory_bot_rails" # mocking/stubbing
  gem "rubocop"
  gem "standard" # Ruby linter
  gem "htmlbeautifier" # html linting
end

group :development do
  gem "listen", ">= 3.0.5", "< 3.2"
  gem "rerun" # For restarting sidekiq on file changes
  gem "hotwire-livereload" # Livereload!
end

group :test do
  gem "guard", require: false
  gem "guard-rspec", require: false
  gem "rails-controller-testing" # Assert testing views
  gem "vcr" # Stub external HTTP requests
  gem "webmock" # mocking for VCR
end

# Performance Stuff
gem "fast_blank" # high performance replacement String#blank? a method that is called quite frequently in ActiveRecord
gem "flamegraph", require: false
gem "stackprof", require: false # Required by flamegraph
gem "rack-mini-profiler", require: ["prepend_net_http_patch"] # If you can't see it you can't make it better
gem "bootsnap", ">= 1.1.0", require: false # Reduces boot times through caching; required in config/boot.rb

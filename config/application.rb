require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
require "action_cable/engine"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module MayIsBikeMonth
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    config.redis_default_url = ENV.fetch("REDIS_URL", "redis://localhost:6379")
    config.redis_cache_url = ENV.fetch("REDIS_CACHE_URL", config.redis_default_url)

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w[assets tasks rails])

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = "America/Los_Angeles"
    config.active_support.to_time_preserves_timezone = :zone
    # config.eager_load_paths << Rails.root.join("extras")

    # Enable instrumentation for ViewComponents (used by rack-mini-profiler)
    config.view_component.instrumentation_enabled = true
    config.view_component.use_deprecated_instrumentation_name = false # Stop annoying deprecation message
    # ^ remove after upgrading to ViewComponent 4
    config.default_preview_layout = "component_preview"
    config.view_component.preview_paths << "#{Rails.root}/app/components/"
    config.lookbook.preview_display_options = {theme: ["light", "dark"]} # Add dynamic 'theme' display option

    config.generators do |g|
      g.factory_bot "true"
      g.helper nil
      g.javascripts nil
      g.stylesheets nil
      g.template_engine nil
      g.serializer nil
      g.assets nil
      g.test_framework :rspec, view_specs: false, routing_specs: false, controller_specs: false
      g.system_tests nil
    end
  end
end

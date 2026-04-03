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
    config.load_defaults 7.1

    config.time_zone = "America/Los_Angeles"
    # config.active_support.to_time_preserves_timezone = :zone # deprecated in Rails 8.2

    config.active_job.queue_adapter = :sidekiq

    config.redis_default_url = ENV.fetch("REDIS_URL")
    config.redis_cache_url = ENV.fetch("REDIS_CACHE_URL", config.redis_default_url)

    config.active_record.schema_format = :ruby

    config.autoload_lib(ignore: %w[assets tasks rails])

    # Enable instrumentation for ViewComponents (used by rack-mini-profiler)
    config.view_component.instrumentation_enabled = true
    config.view_component.default_preview_layout = "component_preview"

    # Add app/components to view paths for component preview templates
    initializer "append_component_views", after: :set_autoload_paths do
      ActiveSupport.on_load(:action_controller) do
        prepend_view_path Rails.root.join("app/components")
      end
    end
    config.importmap.cache_sweepers << Rails.root.join("app/components")
    config.lookbook.preview_display_options = {theme: ["light", "dark"]} if defined?(Lookbook)

    config.generators do |g|
      g.factory_bot "true"
      g.helper nil
      g.javascripts nil
      g.stylesheets nil
      g.template_engine nil
      g.serializer nil
      g.assets nil
      g.test_framework :rspec, view_specs: false, routing_specs: false, controller_specs: false, request_specs: true
      g.system_tests nil
    end
  end
end

if Rails.env != "test"
  require "rack-mini-profiler"
  require "flamegraph"

  # initialization is skipped so trigger it
  Rack::MiniProfilerRails.initialize!(Rails.application)

  Rack::MiniProfiler.config.storage_options = {url: ENV.fetch("REDIS_URL")}
  Rack::MiniProfiler.config.storage = Rack::MiniProfiler::RedisStore
  Rack::MiniProfiler.config.position = "bottom-right"

  Rack::MiniProfilerRails.subscribe("render.view_component") do |_name, start, finish, _id, payload|
    Rack::MiniProfilerRails.render_notification_handler(
      Rack::MiniProfilerRails.shorten_identifier(payload[:identifier]),
      finish,
      start
    )
  end
end

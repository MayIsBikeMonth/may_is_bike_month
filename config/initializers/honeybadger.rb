Honeybadger.configure do |config|
  config.api_key = ENV["HONEYBADGER_API_KEY"]
  config.env = Rails.env
  config.report_data = !Rails.env.development? && !Rails.env.test?
end

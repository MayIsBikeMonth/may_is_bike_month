# Using activejob is slow, use sidekiq
class ApplicationJob
  include Sidekiq::Job

  sidekiq_options queue: "default", backtrace: true
end

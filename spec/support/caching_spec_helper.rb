# frozen_string_literal: true

RSpec.configure do |config|
  config.around(:each, :caching) do |example|
    cache_store = ActiveSupport::Cache::MemoryStore.new
    original_perform_caching = ApplicationController.perform_caching
    original_cache_store = ApplicationController.cache_store
    original_collection_cache = ActionView::PartialRenderer.collection_cache

    ApplicationController.perform_caching = true
    ApplicationController.cache_store = cache_store
    ActionView::PartialRenderer.collection_cache = cache_store

    example.run

    ApplicationController.perform_caching = original_perform_caching
    ApplicationController.cache_store = original_cache_store
    ActionView::PartialRenderer.collection_cache = original_collection_cache
  end
end

RSpec.shared_context :caching_basic do
  # Keys of the fragments a block writes, expanded the way the store sees them. Nothing
  # about the rendered markup says whether it was cached or which parts of the key were
  # there, and a block that writes none rendered entirely from the cache.
  def fragments_written
    keys = []
    subscriber = ActiveSupport::Notifications.subscribe("write_fragment.action_controller") do |_name, _start, _finish, _id, payload|
      keys << ActiveSupport::Cache.expand_cache_key(payload[:key])
    end
    yield
    keys
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end

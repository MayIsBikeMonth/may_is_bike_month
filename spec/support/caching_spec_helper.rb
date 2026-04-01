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

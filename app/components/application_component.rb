# frozen_string_literal: true

class ApplicationComponent < ViewComponent::Base
  include ApplicationComponentHelper

  DEFAULT_INITIAL_UNIT = "imperial"

  # Provide a basic call method for testing
  def call
    content
  end
end

# frozen_string_literal: true

# ApplicationComponent provides the base class for all ViewComponents
class ApplicationComponent < ViewComponent::Base
  include ApplicationComponentHelper

  DEFAULT_INITIAL_UNIT = "imperial"

  # Make unit class methods public for backwards compatibility
  def unit_class_metric
    super
  end

  def unit_class_imperial
    super
  end

  # Provide a basic call method for testing
  def call
    content
  end
end

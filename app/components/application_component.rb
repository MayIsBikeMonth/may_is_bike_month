# frozen_string_literal: true

# Base class for all ViewComponents in the application
class ApplicationComponent < ViewComponent::Base
  include ApplicationComponentHelper

  DEFAULT_INITIAL_UNIT = 'imperial'
end

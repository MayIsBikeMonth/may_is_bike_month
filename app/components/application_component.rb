# frozen_string_literal: true

# ApplicationComponent provides base functionality for all ViewComponents
class ApplicationComponent < ViewComponent::Base
  include ApplicationComponentHelper

  DEFAULT_INITIAL_UNIT = 'imperial'
end

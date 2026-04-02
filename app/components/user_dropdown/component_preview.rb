# frozen_string_literal: true

module UserDropdown
  class ComponentPreview < ApplicationComponentPreview
    # @!group States
    def signed_out
      render(UserDropdown::Component.new(current_user: nil))
    end

    def signed_in
      render(UserDropdown::Component.new(current_user: User.new(display_name: "Rider", strava_username: "rider")))
    end

    # @!endgroup
  end
end

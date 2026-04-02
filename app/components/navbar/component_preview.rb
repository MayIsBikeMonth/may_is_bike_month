# frozen_string_literal: true

module Navbar
  class ComponentPreview < ApplicationComponentPreview
    def default
      render(Navbar::Component.new(current_user: User.new(display_name: "Admin", strava_username: "admin", role: :admin)))
    end
  end
end

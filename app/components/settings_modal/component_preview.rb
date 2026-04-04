# frozen_string_literal: true

module SettingsModal
  class ComponentPreview < ApplicationComponentPreview
    def default
      render(SettingsModal::Component.new(current_user: User.new))
    end
  end
end

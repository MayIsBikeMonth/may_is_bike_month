# frozen_string_literal: true

module UserSettingsModal
  class ComponentPreview < ApplicationComponentPreview
    def default
      render(UserSettingsModal::Component.new(current_user: User.new)) do |modal|
        modal.with_trigger { "Open Settings" }
      end
    end
  end
end

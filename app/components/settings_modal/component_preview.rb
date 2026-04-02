# frozen_string_literal: true

module SettingsModal
  class ComponentPreview < ApplicationComponentPreview
    def default
      render(SettingsModal::Component.new(current_user: User.new)) do |modal|
        modal.with_trigger { tag.button("Open Settings", type: "button", data: {action: "click->modal#open"}) }
      end
    end
  end
end

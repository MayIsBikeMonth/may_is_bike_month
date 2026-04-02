# frozen_string_literal: true

module SettingsModal
  class ComponentPreview < ApplicationComponentPreview
    def default
      render(SettingsModal::Component.new(current_user: User.new)) do |modal|
        modal.with_trigger { "Open Settings" }
      end
    end
  end
end

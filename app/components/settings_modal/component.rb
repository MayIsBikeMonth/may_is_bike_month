# frozen_string_literal: true

module SettingsModal
  class Component < ApplicationComponent
    renders_one :trigger

    def initialize(current_user:)
      @current_user = current_user
    end

    private

    def theme_current_value
      @current_user.try(:theme).presence || "theme_system"
    end
  end
end

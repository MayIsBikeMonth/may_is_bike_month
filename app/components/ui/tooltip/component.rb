# frozen_string_literal: true

module UI::Tooltip
  class Component < ApplicationComponent
    def initialize(text:)
      @text = text
    end

    private

    def tooltip_id
      @tooltip_id ||= "tooltip-#{SecureRandom.hex(4)}"
    end
  end
end

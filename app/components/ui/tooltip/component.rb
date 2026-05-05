# frozen_string_literal: true

module UI
  module Tooltip
    class Component < ApplicationComponent
      TRIGGER_ACTIONS = "mouseenter->ui--tooltip#showOnHover mouseleave->ui--tooltip#hideOnHover " \
        "focusin->ui--tooltip#showOnFocus focusout->ui--tooltip#hideOnFocusout"

      renders_one :body

      def initialize(text: nil, trigger_in_content: false)
        @text = text
        @trigger_in_content = trigger_in_content
      end

      def tooltip_id
        @tooltip_id ||= "tooltip-#{SecureRandom.hex(4)}"
      end

      # Data attrs for a consumer-rendered trigger element. In `trigger_in_content`
      # mode the consumer's element acts as the controller, target, and trigger;
      # merge `extra_action:` to chain non-tooltip actions like `click->punch#toggle`.
      def trigger_data(extra_action: nil)
        action = [extra_action, TRIGGER_ACTIONS].compact.join(" ")
        {controller: "ui--tooltip", "ui--tooltip-target": "trigger", action:}
      end

      def tooltip_span
        tag.span(
          tooltip_body,
          role: "tooltip",
          id: tooltip_id,
          data: {"ui--tooltip-target": "tooltip"},
          class: "hidden pointer-events-none whitespace-nowrap rounded bg-purple-900 px-2 " \
            "py-1 text-xs text-white border border-purple-400 z-50 " \
            "dark:border-purple-300 dark:bg-purple-100 dark:text-purple-900"
        )
      end

      private

      def tooltip_body
        body? ? body : @text
      end
    end
  end
end

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

      def trigger_attrs(data: {})
        action = [data[:action], TRIGGER_ACTIONS].compact.join(" ")
        {
          "aria-describedby": tooltip_id,
          data: {controller: "ui--tooltip", "ui--tooltip-target": "trigger", **data, action:}
        }
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

      def tooltip_id
        @tooltip_id ||= "tooltip-#{SecureRandom.hex(4)}"
      end

      def tooltip_body
        body? ? body : @text
      end
    end
  end
end

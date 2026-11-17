# frozen_string_literal: true

module UI
  module CopyButton
    # `tooltip`, its label and value show in a tooltip, "Copy ID (m/trek/2025/fetch)", rather than its title
    class Component < ApplicationComponent
      BUTTON_CLASS = "group shrink-0 cursor-pointer rounded-sm p-1 " \
        "text-gray-500 hover:bg-gray-100 hover:text-gray-900 " \
        "dark:text-gray-400 dark:hover:bg-gray-700 dark:hover:text-gray-100 " \
        "focus:ring-2 focus:ring-gray-400"

      def initialize(value:, label:, tooltip: false)
        @value = value
        @label = label
        @tooltip = tooltip
      end

      def call
        return tag.button(icons, type: "button", class: BUTTON_CLASS, title: @label, data:) unless @tooltip

        render(UI::Tooltip::Component.new(text: "#{@label} (#{@value})")) do |tooltip|
          tooltip.with_body { safe_join([@label, " (", tag.code(@value, class: "font-mono"), ")"]) }
          tooltip.with_tooltip_button(class: BUTTON_CLASS, data:) { icons }
        end
      end

      private

      def data = {controller: "ui--copy-button", "ui--copy-button-text-value": @value, action: "ui--copy-button#copy"}

      def icons
        safe_join([
          helpers.inline_svg_tag("icons/copy.svg", class: "size-3.5 group-data-copied:hidden", aria_hidden: true),
          helpers.inline_svg_tag("icons/check.svg", class: "hidden size-3.5 text-green-600 group-data-copied:block", aria_hidden: true)
        ])
      end
    end
  end
end

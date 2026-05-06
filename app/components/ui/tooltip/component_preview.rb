# frozen_string_literal: true

module UI
  module Tooltip
    class ComponentPreview < ApplicationComponentPreview
      # @!group Variants
      def default
        render(UI::Tooltip::Component.new(text: "Daily totals only count rides of 2 miles or more")) do
          tag.span(
            "?",
            class: "inline-flex w-4 h-4 items-center justify-center rounded-full " \
              "bg-purple-200 text-purple-900 text-[10px] font-bold " \
              "dark:bg-purple-700 dark:text-purple-100"
          )
        end
      end

      def with_text_trigger
        render(UI::Tooltip::Component.new(text: "More information about this thing")) do
          "hover or focus me"
        end
      end

      def with_tooltip_button_slot
        render(UI::Tooltip::Component.new(text: "May 1: 20.0 mi")) do |tooltip|
          tooltip.with_tooltip_button(class: "punchcard-cell h-7 w-7", data: {l: 3})
        end
      end
      # @!endgroup
    end
  end
end

# frozen_string_literal: true

module UI
  module Tooltip
    class ComponentPreview < ApplicationComponentPreview
      # @!group Variants
      def default
        render(UI::Tooltip::Component.new(text: "5–9 mi")) do
          content_tag(:i, "", class: "block h-5 w-5 rounded bg-purple-400 dark:bg-purple-700 cursor-help")
        end
      end

      def with_text_trigger
        render(UI::Tooltip::Component.new(text: "More information about this thing")) do
          "hover or focus me"
        end
      end
      # @!endgroup
    end
  end
end

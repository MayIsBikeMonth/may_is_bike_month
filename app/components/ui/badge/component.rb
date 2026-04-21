# frozen_string_literal: true

module UI
  module Badge
    class Component < ApplicationComponent
      BASE_CLASSES = "inline-flex border items-center leading-4 rounded-full"

      SIZES = {
        sm: "text-xs font-medium px-1 py-px",
        md: "text-xs font-bold px-2 py-1",
        lg: "text-md font-extrabold px-3 py-1"
      }

      COLORS = {
        notice: "bg-purple-200 text-purple-900 dark:bg-purple-700 dark:text-purple-100",
        error: "bg-red-300 text-red-950 dark:bg-red-800 dark:text-red-300",
        warning: "bg-amber-300 text-amber-900 dark:bg-amber-800 dark:text-amber-200",
        success: "bg-emerald-500 text-emerald-900 dark:bg-emerald-800 dark:text-emerald-200",
        # Special badge classes:
        cyan: "bg-cyan-400 text-cyan-900 dark:bg-cyan-800 dark:text-cyan-200",
        gray: "bg-gray-300 text-gray-900 dark:bg-gray-700 dark:text-gray-200",
        purple: "bg-purple-300 text-purple-900 dark:bg-purple-600 dark:text-purple-100",
        rose: "bg-rose-400 text-rose-950 dark:bg-rose-800 dark:text-rose-300",
        orange: "bg-orange-400 text-orange-950 dark:bg-orange-800 dark:text-orange-300",
        empty: "bg-white text-gray-700 border-gray-300 dark:bg-gray-900 dark:text-gray-200 dark:border-gray-600"
      }.freeze

      def self.badge_classes(color:, size:, cursor: "cursor-default")
        [BASE_CLASSES, cursor, COLORS[color], SIZES[size]].join(" ")
      end

      def initialize(text:, title: nil, color: :gray, size: :md)
        @text = text
        @title = title
        @color = COLORS.key?(color) ? color : :gray
        @size = SIZES.include?(size) ? size : :md
      end

      def call
        badge = content_tag(:span, content.presence || @text, class: badge_class)
        return badge unless custom_title?
        render(UI::Tooltip::Component.new(text: @title)) { badge }
      end

      private

      def custom_title?
        @title.present? && @title != @text
      end

      def badge_class
        self.class.badge_classes(color: @color, size: @size, cursor: custom_title? ? "cursor-help" : "cursor-default")
      end
    end
  end
end

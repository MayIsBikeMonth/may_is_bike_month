# frozen_string_literal: true

module UI
  module Button
    class Component < ApplicationComponent
      BASE_CLASSES = "inline-flex items-center gap-1.5 rounded-lg cursor-pointer transition-colors"

      SIZES = {
        sm: "px-2.5 py-1 text-xs",
        md: "px-3 py-1.5 text-sm",
        lg: "px-4 py-2 text-base"
      }.freeze

      COLORS = {
        primary: "text-white bg-purple-500 border border-purple-500 hover:bg-purple-600 active:bg-purple-700 focus:ring-purple-400/40 dark:bg-purple-400 dark:border-purple-400 dark:hover:bg-purple-500 dark:active:bg-purple-600",
        secondary: "text-gray-700 bg-white border border-gray-300 hover:bg-gray-50 hover:border-gray-400 active:bg-gray-100 focus:ring-purple-400/40 dark:text-gray-200 dark:bg-gray-800 dark:border-gray-600 dark:hover:bg-gray-700 dark:hover:border-gray-500 dark:active:bg-gray-600",
        error: "text-white bg-red-600 border border-red-600 hover:bg-red-700 active:bg-red-800 focus:ring-red-500/40 dark:bg-red-500 dark:border-red-500 dark:hover:bg-red-600 dark:active:bg-red-700",
        link: "text-purple-300 dark:text-purple-400 hover:text-purple-500 dark:hover:text-purple-200 hover:underline aria-pressed:text-purple-500 aria-pressed:underline dark:aria-pressed:text-purple-200"
      }.freeze

      ACTIVE_COLORS = {
        primary: "ring-2 ring-purple-400/40 bg-purple-600 dark:bg-purple-500",
        secondary: "ring-2 ring-purple-400/40 bg-gray-100 border-gray-400 dark:bg-gray-700 dark:border-gray-500",
        error: "ring-2 ring-red-500/40 bg-red-700 dark:bg-red-600",
        link: "text-purple-500 dark:text-purple-200 underline"
      }.freeze

      KINDS = %i[button submit]

      def self.build_classes(color:, size:, active: false, html_class: nil)
        classes = [BASE_CLASSES, COLORS[color], html_class]
        unless color == :link
          classes << SIZES[size]
          classes << "focus:outline-none focus:ring-3 font-medium"
        end
        classes << ACTIVE_COLORS[color] if active
        classes.compact.join(" ")
      end

      def initialize(text: nil, color: :secondary, size: :md, active: false, html_class: nil, kind: nil, data: {}, aria: {})
        @text = text
        @color = COLORS.key?(color) ? color : :secondary
        @kind = KINDS.include?(kind&.to_sym) ? kind.to_sym : KINDS.first
        @active = active
        @html_class = html_class
        @data = data
        @aria = aria
        @size = SIZES.key?(size) ? size : :md
        raise ArgumentError, "size is not supported for link color" if @color == :link && @size != :md
      end

      def button_classes
        self.class.build_classes(color: @color, size: @size, active: @active, html_class: @html_class)
      end

      def call
        content_tag(:button, @text || content, class: button_classes, type: (@kind == :submit) ? "submit" : "button", data: @data, aria: @aria)
      end
    end
  end
end

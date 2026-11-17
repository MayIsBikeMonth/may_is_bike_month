# frozen_string_literal: true

module UI
  module Badge
    class Component < ApplicationComponent
      BASE_CLASSES = "inline-flex border items-center leading-4 rounded-full"

      SIZES = {
        xs: "text-2xs font-semibold px-[7px] py-px",
        sm: "text-xs font-medium px-1 py-px",
        md: "text-xs font-bold px-2 py-1",
        lg: "text-sm font-extrabold px-3 py-1",
        inherit: "text-[length:inherit] font-bold px-2 py-px"
      }

      # Soft tinted pills matching the redesign: light background + saturated text
      COLORS = {
        notice: "bg-blue-50 text-blue-700 border-transparent dark:bg-blue-400/15 dark:text-blue-200",
        error: "bg-red-50 text-red-700 border-transparent dark:bg-red-400/15 dark:text-red-200",
        warning: "bg-yellow-50 text-yellow-800 border-transparent dark:bg-yellow-300/25 dark:text-yellow-200",
        success: "bg-green-50 text-green-700 border-transparent dark:bg-green-400/15 dark:text-green-200",
        # Special badge classes:
        cyan: "bg-cyan-50 text-cyan-700 border-transparent dark:bg-cyan-400/15 dark:text-cyan-200",
        # The redesign's quiet pill. Text is --redesign-gray-500 rather than the
        # mockup's #9a9aa2, which sat at 2.45:1 on this background.
        gray: "bg-[#f0f0f2] text-[#666666] border-transparent dark:bg-white/10 dark:text-gray-400",
        purple: "bg-purple-50 text-purple-700 border-transparent dark:bg-purple-400/15 dark:text-purple-200",
        # The -400 rather than the palette's -700, by choice: 2.5:1 on its own background,
        # so it reads softer than every other pill rather than as a mistyped shade
        pink: "bg-pink-50 text-pink-400 border-transparent dark:bg-pink-400/15 dark:text-pink-400",
        rose: "bg-rose-50 text-rose-700 border-transparent dark:bg-rose-400/15 dark:text-rose-200",
        orange: "bg-orange-50 text-orange-700 border-transparent dark:bg-orange-400/15 dark:text-orange-200",
        empty: "bg-white text-gray-700 border-gray-300 dark:bg-gray-900 dark:text-gray-200 dark:border-gray-600",
        # UI::Button's yellow
        yellow: "bg-yellow-300 text-slate-900 border-transparent"
      }.freeze

      # Solid pills (saturated background + white text) — e.g. the redesign audience pill
      SOLID_COLORS = {
        notice: "bg-blue-500 text-white border-transparent",
        error: "bg-red-600 text-white border-transparent dark:bg-red-700",
        warning: "bg-yellow-300 text-slate-900 border-transparent",
        success: "bg-green-600 text-white border-transparent",
        cyan: "bg-cyan-500 text-white border-transparent",
        gray: "bg-gray-500 text-white border-transparent",
        purple: "bg-purple-500 text-white border-transparent",
        pink: "bg-pink-500 text-white border-transparent",
        rose: "bg-rose-500 text-white border-transparent",
        orange: "bg-orange-500 text-white border-transparent",
        empty: "bg-gray-500 text-white border-transparent"
      }.freeze

      def self.badge_classes(color:, size:, cursor: "cursor-default", solid: false)
        palette = solid ? SOLID_COLORS : COLORS
        [BASE_CLASSES, cursor, palette[color], SIZES[size]].join(" ")
      end

      def initialize(text:, title: nil, color: :gray, size: :md, indicator: false, solid: false, icon: nil)
        @text = text
        @title = title
        @color = COLORS.key?(color) ? color : :gray
        @size = SIZES.include?(size) ? size : :md
        @indicator = indicator
        @solid = solid
        @icon = icon
      end

      def call
        leading = leading_element
        label = content.presence || @text
        label = safe_join([leading, label]) if leading
        badge = content_tag(:span, label, class: badge_class)
        return badge unless custom_title?
        render(UI::Tooltip::Component.new(text: @title)) { badge }
      end

      private

      # An inline icon (@icon is a path under app/assets/images, sans .svg) takes
      # precedence over the status dot. Both are decorative - the badge's text is
      # its accessible name - so they stay out of the accessibility tree.
      def leading_element
        return helpers.inline_svg_tag("#{@icon}.svg", class: "mr-1 size-3.5", aria_hidden: true) if @icon.present?
        indicator_dot if @indicator
      end

      # A small status dot inheriting the badge's text color
      def indicator_dot
        content_tag(:span, "", class: "mr-1.5 inline-block size-1.5 rounded-full bg-current", aria: {hidden: true})
      end

      def custom_title?
        @title.present? && @title != @text
      end

      def badge_class
        self.class.badge_classes(color: @color, size: @size, solid: @solid, cursor: custom_title? ? "cursor-help" : "cursor-default")
      end
    end
  end
end

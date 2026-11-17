# frozen_string_literal: true

module UI
  module ColorSwatch
    # A small square showing a color. The display-less "cover-up" color
    # renders Color::COVER_UP_SWATCH's multicolor blend instead of a solid fill.
    #
    # Decorative: every caller prints a name beside the swatch, so giving the
    # swatch an accessible name of its own would announce "Red Red".
    class Component < ApplicationComponent
      # leading-[0] collapses the empty box's line-height strut so align-baseline
      # sits its bottom on the text baseline instead of floating above it
      BASE_CLASSES = "inline-block leading-[0] rounded-xs border border-black/20 dark:border-white/20"

      SIZES = {sm: "h-3 w-3", md: "h-6 w-6"}.freeze

      ALIGNS = {middle: "align-middle", baseline: "align-baseline"}.freeze

      def initialize(display: nil, name: nil, size: :md, align: :middle)
        @display = display.presence
        @name = name.presence
        @size = SIZES.key?(size) ? size : :md
        @align = ALIGNS.key?(align) ? align : :middle
      end

      def call
        content_tag(:span, "", class: "#{BASE_CLASSES} #{SIZES[@size]} #{ALIGNS[@align]}", style: swatch_style, aria: {hidden: true})
      end

      private

      def cover_up?
        @name == Color::COVER_UP_NAME
      end

      def swatch_style
        "background: #{cover_up? ? Color::COVER_UP_SWATCH : @display}"
      end
    end
  end
end

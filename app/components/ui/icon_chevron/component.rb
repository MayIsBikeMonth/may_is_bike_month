# frozen_string_literal: true

module UI
  module IconChevron
    class Component < ApplicationComponent
      ROTATIONS = {
        right: nil,
        down: "rotate-90",
        left: "rotate-180",
        up: "rotate-270"
      }.freeze

      SIZES = {
        sm: "h-3 w-3",
        md: "h-4 w-4"
      }.freeze

      def initialize(direction: :right, size: :sm, html_class: nil)
        @direction = ROTATIONS.key?(direction) ? direction : :right
        @size = SIZES.key?(size) ? size : :sm
        @html_class = html_class
      end

      def call
        helpers.inline_svg_tag("icons/chevron-right.svg",
          class: ["inline-block", SIZES[@size], ROTATIONS[@direction], @html_class].compact.join(" "))
      end
    end
  end
end

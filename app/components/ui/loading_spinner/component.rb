# frozen_string_literal: true

module UI
  module LoadingSpinner
    class Component < ApplicationComponent
      SIZES = {
        sm: "h-3 w-3",
        md: "h-15 w-15"
      }.freeze

      # A nil color_class leaves the svg inheriting currentColor from its surroundings
      def initialize(text: nil, size: :md, color_class: "text-slate-400 dark:text-blue-800")
        @text = text
        @size = SIZES.key?(size) ? size : :md
        @color_class = color_class
      end

      def call
        if inline?
          spinner_svg
        else
          content_tag(:div, class: "animate-pulse justify-center p-6 text-center") do
            safe_join([content_tag(:p, @text, class: "text-lg"), spinner_svg])
          end
        end
      end

      def inline?
        @text.blank?
      end

      private

      def spinner_svg
        classes = ["animate-spin", @color_class.presence, SIZES[@size]].compact.join(" ")
        classes = "inline #{classes}" if inline?
        classes = "mx-auto mt-4 #{classes}" unless inline?

        helpers.inline_svg_tag("kelsey/illustrations/bike_wheel.svg", class: classes, aria_hidden: true)
      end
    end
  end
end

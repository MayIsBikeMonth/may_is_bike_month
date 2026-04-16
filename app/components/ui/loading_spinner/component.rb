# frozen_string_literal: true

module UI::LoadingSpinner
  class Component < ApplicationComponent
    SIZES = {
      sm: "h-3 w-3",
      md: "h-15 w-15"
    }.freeze

    def initialize(text: nil, size: :md)
      @text = text
      @size = SIZES.key?(size) ? size : :md
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
      classes = "animate-spin text-slate-400 dark:text-blue-800 #{SIZES[@size]}"
      classes = "inline #{classes}" if inline?
      classes = "mx-auto mt-4 #{classes}" unless inline?

      content_tag(:svg, class: classes, xmlns: "http://www.w3.org/2000/svg",
        fill: "none", viewBox: "0 0 24 24") do
        safe_join([
          tag.circle(class: "opacity-25", cx: "12", cy: "12", r: "10",
            stroke: "currentColor", "stroke-width": "4"),
          tag.path(class: "opacity-75", fill: "currentColor",
            d: "M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z")
        ])
      end
    end
  end
end

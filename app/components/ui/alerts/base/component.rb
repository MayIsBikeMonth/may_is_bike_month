# frozen_string_literal: true

module UI
  module Alerts
    module Base
      class Component < ApplicationComponent
        TEXT_CLASSES = {
          notice: "text-blue-800 dark:text-blue-300",
          error: "text-red-800 dark:text-red-300",
          warning: "text-yellow-800 dark:text-yellow-400",
          success: "text-green-800 dark:text-green-300",
          purple: "text-purple-800 dark:text-purple-200"
        }.freeze
        KINDS = TEXT_CLASSES.keys.freeze

        # icon: rendered markup, e.g. inline_svg_tag("icons/envelope.svg", class: "h-4 w-4") -
        # replaces the default info icon
        def initialize(text: nil, header: nil, kind: :notice, dismissable: false, margin_classes: "mb-4", icon: nil,
          default_header_color: false)
          @text = text
          @header = header
          @kind = normalized_kind(kind)
          @dismissable = dismissable
          @margin_classes = margin_classes
          @icon = icon
          @default_header_color = default_header_color
        end

        private

        # What a screen reader reads in place of the icon. :purple names a color rather
        # than a meaning, so it announces the meaning it actually carries
        def announcement
          case @kind
          when :error then "Error"
          when :warning then "Warning"
          when :success then "Success"
          when :purple then "Info"
          else "Notice"
          end
        end

        def normalized_kind(kind)
          return kind.to_sym if KINDS.include?(kind&.to_sym)

          unless Rails.env.production?
            raise ArgumentError, "unknown kind #{kind.inspect}, expected one of: #{KINDS.join(", ")}"
          end

          Honeybadger.notify("Unknown alert kind", {error_class: self.class.to_s, context: {kind:}})
          KINDS.first
        end

        # Give the float the line-height of the line it shares, so it centers on that
        # line alone -- taller for a header
        def icon_classes
          @header.present? ? "h-7" : "h-6"
        end

        def default_icon
          (@kind == :error) ? "icons/exclamation-triangle.svg" : "icons/info.svg"
        end

        # Dark backgrounds are the 25% tint pre-mixed onto the page's gray-900, not an alpha:
        # a flash floats over content, which showed through
        def color_classes
          case @kind
          when :notice
            "#{text_color_classes} bg-blue-50 dark:bg-[color-mix(in_srgb,var(--color-blue-500)_25%,var(--color-gray-900))] border-blue-300 dark:border-blue-500/50"
          when :error
            "#{text_color_classes} bg-red-50 dark:bg-[color-mix(in_srgb,var(--color-red-500)_25%,var(--color-gray-900))] border-red-300 dark:border-red-500/50"
          when :warning
            "#{text_color_classes} bg-yellow-50 dark:bg-[color-mix(in_srgb,var(--color-yellow-300)_25%,var(--color-gray-900))] border-yellow-300 dark:border-yellow-300/50"
          when :success
            "#{text_color_classes} bg-green-50 dark:bg-[color-mix(in_srgb,var(--color-green-500)_25%,var(--color-gray-900))] border-green-300 dark:border-green-500/50"
          when :purple
            "#{text_color_classes} bg-purple-50 dark:bg-[color-mix(in_srgb,var(--color-purple-500)_25%,var(--color-gray-900))] border-purple-300 dark:border-purple-500/50"
          end
        end

        def text_color_classes
          TEXT_CLASSES[@kind]
        end

        def header_color_classes
          @default_header_color ? "twtext-color" : text_color_classes
        end

        def dismissable_color_classes
          case @kind
          when :notice
            "bg-blue-50 focus:ring-blue-400 hover:bg-blue-200 dark:bg-transparent dark:hover:bg-blue-500/25"
          when :error
            "bg-red-50 focus:ring-red-400 hover:bg-red-200 dark:bg-transparent dark:hover:bg-red-500/25"
          when :warning
            "bg-yellow-50 focus:ring-yellow-400 hover:bg-yellow-200 dark:bg-transparent dark:hover:bg-yellow-300/25"
          when :success
            "bg-green-50 focus:ring-green-400 hover:bg-green-200 dark:bg-transparent dark:hover:bg-green-500/25"
          when :purple
            "bg-purple-50 focus:ring-purple-400 hover:bg-purple-200 dark:bg-transparent dark:hover:bg-purple-500/25"
          end
        end
      end
    end
  end
end

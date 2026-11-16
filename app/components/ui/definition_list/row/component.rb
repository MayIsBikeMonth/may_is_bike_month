# frozen_string_literal: true

module UI
  module DefinitionList
    module Row
      class Component < ApplicationComponent
        def initialize(label:, value: nil, render_with_no_value: false, no_value_text: nil, full_width: false, time_localizer_settings: nil)
          @label = label
          @value = value
          @render_with_no_value = render_with_no_value
          @no_value_text = no_value_text
          @full_width = full_width

          # TODO: actually support originalTimeZone. When this is set currently, we show the timezone,
          # but it's still the user's timezone
          @include_time_zone = time_localizer_settings&.include?(:originalTimeZone) || false

          @time_localizer_classes = time_localizer_classes(time_localizer_settings)
        end

        def render?
          return true if @render_with_no_value

          @value.present? || content.present?
        end

        private

        def render_convertime?
          @value.present? && (@value.is_a?(::Time) || @value.is_a?(Date))
        end

        def no_value_content
          @no_value_text || "none"
        end

        def wrapper_classes
          if @full_width
            "col-span-full"
          else
            "flex items-baseline justify-between gap-x-4"
          end + " pt-3 leading-tight"
        end

        def dt_classes
          if @full_width
            "pb-1"
          else
            "flex-none"
          end + " text-sm leading-tight opacity-65"
        end

        def dd_classes
          @full_width ? "mb-0" : "mb-0 text-right"
        end

        def time_localizer_classes(time_localizer_settings)
          time_localizer_settings ||= []
          time_localizer_settings << "localizeTime"
          time_localizer_settings.join(" ")
        end
      end
    end
  end
end

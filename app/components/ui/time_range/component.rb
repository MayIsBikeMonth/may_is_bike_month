# frozen_string_literal: true

module UI
  module TimeRange
    class Component < ApplicationComponent
      # A minute-bucketed range's endpoints differ only in their seconds
      TIME_FORMATS = {group_by_minute: :localize_time_precise_seconds,
                      group_by_hour: :localize_time_precise}.freeze

      def initialize(time_range:, period:)
        @time_range = time_range
        @period = period
      end

      def call
        return h(period_phrase) unless @period == "custom"

        content_tag(:span) do
          safe_join(["from", tag.em(render(endpoint(@time_range.first))),
            "to", tag.em(ends_now? ? "now" : render(endpoint(@time_range.last)))], " ")
        end
      end

      private

      def render? = @period.present? && @period != "all"

      # A whole sentence per period, so a locale can inflect it
      def period_phrase
        case @period
        when "hour" then "in the past hour"
        when "day" then "in the past day"
        when "week" then "in the past week"
        when "month" then "in the past month"
        when "year" then "in the past year"
        when "next_week" then "in the next week"
        when "next_month" then "in the next month"
        end
      end

      def endpoint(time)
        UI::Time::Component.new(time:, format: TIME_FORMATS[helpers.group_by_method(@time_range)])
      end

      # Anything this recent was "now" when the range was built
      def ends_now? = @time_range.last > ::Time.current - 5.minutes
    end
  end
end

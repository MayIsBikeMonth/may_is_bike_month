# frozen_string_literal: true

module Punchcard::Ridge
  class Component < ApplicationComponent
    MAX_BAR_PX = 56

    BUTTON_CLASS = "flex flex-col items-stretch p-0 border-0 bg-transparent " \
      "cursor-pointer outline-none rounded-[1px] transition-shadow " \
      "hover:ring-1 hover:ring-purple-300 dark:hover:ring-purple-600 " \
      "focus-visible:ring-[2px] focus-visible:ring-purple-400 " \
      "dark:focus-visible:ring-purple-500 aria-pressed:ring-2 " \
      "aria-pressed:ring-purple-700 dark:aria-pressed:ring-purple-100"

    SPAN_CLASS = "flex flex-col items-stretch rounded-[1px]"

    BAR_GRADIENT_CLASS = "block w-full bg-gradient-to-b from-purple-300 " \
      "to-purple-500 dark:from-purple-700 dark:to-purple-500 rounded-[1px] " \
      "opacity-90"

    BAR_EMPTY_CLASS = "block w-full rounded-[1px]"

    def initialize(daily_totals:)
      @daily_totals = daily_totals
    end

    private

    def bar_tag(bar, &)
      extra_class = " pb-1" if bar[:weekend_label]
      if bar[:upcoming]
        tag.span(class: "#{SPAN_CLASS}#{extra_class}", title: bar[:title], &)
      else
        tag.button(
          type: "button",
          class: "#{BUTTON_CLASS}#{extra_class}",
          title: bar[:title],
          "aria-pressed": "false",
          data: {action: "click->punch#toggleDay", "punch-target": "ridgeBar", date: bar[:date_string]},
          &
        )
      end
    end

    def bars
      @bars ||= build_bars
    end

    def build_bars
      max_distance = @daily_totals.map { |d| d[:distance_meters] }.max.to_f
      max_distance = 1 if max_distance.zero?

      today = Date.current
      @daily_totals.map do |day|
        miles = meters_to_miles(day[:distance_meters])
        feet = meters_to_feet(day[:elevation_meters])
        height_px = (day[:distance_meters] / max_distance) * MAX_BAR_PX
        date = Date.parse(day[:date_string])
        day_of_week = date.strftime("%A")
        upcoming = date > today
        activities = "#{number_with_delimiter(day[:activity_count])} #{"activity".pluralize(day[:activity_count])}"
        {
          height_px:,
          date_string: day[:date_string],
          day: date.day,
          title: upcoming ? day_of_week : "#{day_of_week}\n#{activities}\n#{miles.round(1)} mi\n#{number_with_delimiter(feet.to_i)} ft",
          upcoming:,
          weekend_label: (date.strftime("%a") if date.saturday? || date.sunday?)
        }
      end
    end
  end
end

# frozen_string_literal: true

module Punchcard::Ridge
  class Component < ApplicationComponent
    MAX_BAR_PX = 56
    def initialize(daily_totals:)
      @daily_totals = daily_totals
    end

    private

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
        upcoming = date >= today
        {
          height_px:,
          date_string: day[:date_string],
          day: date.day,
          title: upcoming ? day_of_week : "#{day_of_week}\n#{miles.round(1)} mi\n#{number_with_delimiter(feet.to_i)} ft",
          upcoming:,
          weekend_label: (date.strftime("%a") if date.saturday? || date.sunday?)
        }
      end
    end
  end
end

# frozen_string_literal: true

module Punchcard::Ridge
  class Component < ApplicationComponent
    def initialize(daily_totals:)
      @daily_totals = daily_totals
    end

    private

    def bars
      max_distance = @daily_totals.map { |d| d[:distance_meters] }.max.to_f
      max_distance = 1 if max_distance.zero?

      @daily_totals.map do |day|
        miles = meters_to_miles(day[:distance_meters])
        feet = meters_to_feet(day[:elevation_meters])
        height = (day[:distance_meters] / max_distance) * 100
        day_of_week = Date.parse(day[:date_string]).strftime("%A")
        {
          height:,
          title: "#{day_of_week}\n#{miles.round(1)} mi\n#{number_with_delimiter(feet.to_i)} ft"
        }
      end
    end
  end
end

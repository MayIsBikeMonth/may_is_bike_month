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
        miles = day[:distance_meters] / PunchcardData::MILE_METERS
        feet = day[:elevation_meters] * 3.28084
        height = (day[:distance_meters] / max_distance) * 100
        {
          height:,
          title: "#{miles.round(1)} mi\n#{number_with_delimiter(feet.to_i)} ft"
        }
      end
    end
  end
end

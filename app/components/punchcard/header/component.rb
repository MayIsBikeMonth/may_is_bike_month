# frozen_string_literal: true

module Punchcard::Header
  class Component < ApplicationComponent
    def initialize(competition:, rider_count:, distance_meters:, elevation_meters:, everyday_rider_count:)
      @competition = competition
      @rider_count = rider_count
      @distance_meters = distance_meters
      @elevation_meters = elevation_meters
      @everyday_rider_count = everyday_rider_count
    end

    private

    def total_miles = meters_to_miles(@distance_meters)
    def total_km = @distance_meters / 1000.0
    def total_feet = meters_to_feet(@elevation_meters)
    def total_meters = @elevation_meters

    def thousands_display(value)
      rounded = value.to_i.round(-3) / 1_000
      safe_join([number_display(rounded), tag.span("k", class: "opacity-40")])
    end
  end
end

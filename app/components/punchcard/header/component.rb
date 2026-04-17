# frozen_string_literal: true

module Punchcard::Header
  class Component < ApplicationComponent
    def initialize(competition:, rider_count:, total_miles:, total_feet:, everyday_rider_count:)
      @competition = competition
      @rider_count = rider_count
      @total_miles = total_miles
      @total_feet = total_feet
      @everyday_rider_count = everyday_rider_count
    end

    private

    def total_km
      @total_miles * 1.609344
    end

    def total_meters
      @total_feet / 3.28084
    end

    def thousands_display(value)
      rounded = value.to_i.round(-3) / 1_000
      safe_join([number_with_delimiter(rounded), tag.span("k", class: "opacity-40")])
    end
  end
end

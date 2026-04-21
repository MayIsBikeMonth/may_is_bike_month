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

    def title_html
      year = @competition.year.to_s
      name = @competition.display_name.to_s
      highlighted = tag.b(year, class: "text-purple-500 dark:text-purple-400 font-bold")
      before, matched, after = name.rpartition(year)
      return safe_join([name, " ", highlighted]) if matched.empty?
      safe_join([before, highlighted, after])
    end

    def days_left
      @days_left ||= (Date.current..@competition.end_date).count
    end

    def competition_over? = days_left.zero?

    def legacy? = @competition.legacy?

    def metric_grid_class
      count = 3
      count += 1 unless competition_over?
      count += 1 unless legacy?
      "grid-cols-[repeat(#{count},auto)]"
    end

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

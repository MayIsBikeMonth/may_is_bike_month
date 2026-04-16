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

    def feet_in_thousands
      (@total_feet.to_i.round(-3) / 1_000) if @total_feet >= 1_000
    end

    def feet_remainder
      feet_in_thousands ? nil : @total_feet.to_i
    end
  end
end

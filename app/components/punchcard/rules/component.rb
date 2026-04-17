# frozen_string_literal: true

module Punchcard::Rules
  class Component < ApplicationComponent
    def initialize(competition:)
      @competition = competition
    end

    private

    def daily_distance_miles
      meters_to_miles(@competition.daily_distance_requirement).round
    end

    def daily_distance_km
      (@competition.daily_distance_requirement / 1000.0).round
    end

    def activity_types_display
      (@competition.activity_types - %w[Handcycle Velomobile]).reverse.to_sentence
    end
  end
end

# frozen_string_literal: true

module Punchcard::Rules
  class Component < ApplicationComponent
    def initialize(competition:)
      @competition = competition
    end

    private

    def daily_distance_miles
      (@competition.daily_distance_requirement / PunchcardData::MILE_METERS).round
    end

    def activity_types_display
      (@competition.activity_types - %w[Handcycle Velomobile]).reverse.to_sentence
    end
  end
end

# frozen_string_literal: true

module Punchcard::UserPunch
  class Component < ApplicationComponent
    CENTURY_MILES = 100

    def initialize(date_string:, distance_meters:, competition:)
      @date_string = date_string
      @distance_meters = distance_meters
      @competition = competition
    end

    def call
      data = {}
      data[:l] = level if level
      data[:century] = true if century?
      tag.span(class: "punchcard-cell", title:, data:)
    end

    private

    def miles
      @miles ||= meters_to_miles(@distance_meters)
    end

    def level
      @level ||= begin
        thresholds = Punchcard::Wrapper::Component.level_thresholds(@competition)
        thresholds.keys.rfind { |l| miles >= thresholds[l] }
      end
    end

    def century?
      miles >= CENTURY_MILES
    end

    def title
      level ? "#{@date_string}: #{miles.round(1)} mi" : "no rides"
    end
  end
end

# frozen_string_literal: true

module Punchcard::Footer
  class Component < ApplicationComponent
    MILE_KM = 1.609344

    LEVEL_COLOR_CLASSES = {
      1 => "bg-purple-200 dark:bg-purple-900",
      2 => "bg-purple-300 dark:bg-purple-800",
      3 => "bg-purple-400 dark:bg-purple-700",
      4 => "bg-purple-500 dark:bg-purple-600",
      5 => "bg-purple-600 dark:bg-purple-500"
    }.freeze

    def initialize(updated_at:, competition:, competitions: [])
      @updated_at = updated_at
      @competition = competition
      @competitions = competitions
    end

    private

    def swatches
      pairs = Punchcard::Wrapper::Component.level_thresholds(@competition).to_a
      pairs.map.with_index do |(level, min_mi), i|
        next_mi = pairs[i + 1]&.last
        {
          color_class: LEVEL_COLOR_CLASSES[level],
          title_imperial: range_title(min_mi, next_mi, "mi"),
          title_metric: range_title(min_mi * MILE_KM, next_mi&.*(MILE_KM), "km")
        }
      end
    end

    def range_title(min, next_min, unit)
      if next_min
        "#{min.round}–#{(next_min - 1).round} #{unit}"
      else
        "#{min.round}+ #{unit}"
      end
    end
  end
end

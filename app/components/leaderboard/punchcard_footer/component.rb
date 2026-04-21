# frozen_string_literal: true

module Leaderboard
  module PunchcardFooter
    class Component < ApplicationComponent
      MILE_KM = 1.609344

      def initialize(updated_at:, competition:, competitions: [])
        @updated_at = updated_at
        @competition = competition
        @competitions = competitions
      end

      private

      def swatches
        pairs = Leaderboard::PunchcardWrapper::Component.level_thresholds(@competition).to_a
        below_min = {
          level: nil,
          title_imperial: not_counted_title("mi", meters_to_miles(@competition.daily_distance_requirement)),
          title_metric: not_counted_title("km", @competition.daily_distance_requirement / 1000.0)
        }
        levels = pairs.map.with_index do |(level, min_mi), i|
          next_mi = pairs[i + 1]&.last
          {
            level:,
            title_imperial: range_title(min_mi, next_mi, "mi"),
            title_metric: range_title(min_mi * MILE_KM, next_mi&.*(MILE_KM), "km")
          }
        end
        [below_min, *levels]
      end

      def not_counted_title(unit, distance)
        "Didn't ride required #{distance.round} #{unit}"
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
end

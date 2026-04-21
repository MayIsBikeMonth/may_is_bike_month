# frozen_string_literal: true

module Leaderboard
  module LegacyCompetitionWrapper
    class Component < ApplicationComponent
      GRID_CLASSES = "grid [grid-template-columns:var(--legacy-grid-mobile)] lg:[grid-template-columns:var(--legacy-grid-desktop)]"

      def initialize(competition:, competition_users:, competitions: [])
        @competition = competition
        @competition_users = competition_users
        @competitions = competitions
      end

      private

      def periods
        @periods ||= @competition.periods
      end

      def period_label(period)
        start_date = Date.parse(period[:start_date])
        end_date = Date.parse(period[:end_date])
        "#{start_date.strftime("%b %-d")}–#{end_date.strftime("%-d")}"
      end

      def grid_classes
        GRID_CLASSES
      end

      def grid_style
        "--legacy-grid-desktop: 40px minmax(120px, 1fr) repeat(#{periods.size}, minmax(68px, 1fr)) 110px; " \
          "--legacy-grid-mobile: 40px minmax(120px, 1fr) 110px repeat(#{periods.size}, minmax(68px, 1fr));"
      end

      def total_distance_meters
        @total_distance_meters ||= @competition_users.sum(&:distance_meters)
      end

      def total_elevation_meters
        @total_elevation_meters ||= @competition_users.sum(&:elevation_meters)
      end

      def any_activities?
        @competition_users.any? { |cu| cu.competition_activities_included.any? }
      end
    end
  end
end

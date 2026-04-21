# frozen_string_literal: true

module Leaderboard
  module LegacyCompetition
    class Component < ApplicationComponent
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

      def period_entries(competition_user)
        stored = competition_user.score_data&.dig("periods") || []
        periods.map do |period|
          stored.find { |p| p["start_date"] == period[:start_date] } ||
            {"distance" => 0, "elevation" => 0}
        end
      end

      def total_distance_meters
        @total_distance_meters ||= @competition_users.sum(&:distance_meters)
      end

      def total_elevation_meters
        @total_elevation_meters ||= @competition_users.sum(&:elevation_meters)
      end
    end
  end
end

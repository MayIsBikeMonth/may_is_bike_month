# frozen_string_literal: true

module Leaderboard
  module LegacyCompetitionUserRow
    class Component < ApplicationComponent
      def initialize(competition_user:, competition:, rank:, periods:, grid_classes:)
        @competition_user = competition_user
        @competition = competition
        @rank = rank
        @periods = periods
        @grid_classes = grid_classes
      end

      private

      def period_entries
        stored = @competition_user.score_data&.dig("periods") || []
        @periods.map do |period|
          stored.find { |p| p["start_date"] == period[:start_date] } ||
            {"distance" => 0, "elevation" => 0}
        end
      end

      def has_activities?
        @competition_user.competition_activities_included.any?
      end

      def user_slug
        @competition_user.user.slug
      end
    end
  end
end

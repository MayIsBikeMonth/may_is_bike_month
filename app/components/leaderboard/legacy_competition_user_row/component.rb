# frozen_string_literal: true

module Leaderboard
  module LegacyCompetitionUserRow
    class Component < ApplicationComponent
      def initialize(competition_user:, competition:, rank:)
        @competition_user = competition_user
        @competition = competition
        @rank = rank
      end

      private

      def grid_classes
        Leaderboard::LegacyCompetitionWrapper::Component::GRID_CLASSES
      end

      def period_entries
        stored = @competition_user.score_data&.dig("periods") || []
        @competition.periods.map do |period|
          stored.find { |p| p["start_date"] == period[:start_date] } ||
            {"distance" => 0, "elevation" => 0}
        end
      end

      def has_activities?
        return @has_activities if defined?(@has_activities)
        @has_activities = @competition_user.competition_activities_included.any?
      end

      def user_slug
        @competition_user.user.slug
      end
    end
  end
end

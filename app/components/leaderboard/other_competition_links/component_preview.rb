# frozen_string_literal: true

module Leaderboard
  module OtherCompetitionLinks
    class ComponentPreview < ApplicationComponentPreview
      def default
        competitions = sample_competitions
        render(Leaderboard::OtherCompetitionLinks::Component.new(
          competitions:,
          current_competition: competitions.find { |c| c.year == 2025 }
        ))
      end

      def original_view
        competitions = sample_competitions
        render(Leaderboard::OtherCompetitionLinks::Component.new(
          competitions:,
          current_competition: competitions.find { |c| c.year == 2024 },
          original_view: true
        ))
      end

      def multiple_per_year
        competitions = [
          Competition.new(start_date: Date.new(2026, 5, 1), display_name: "MIBM 2026"),
          Competition.new(start_date: Date.new(2025, 5, 1), display_name: "MIBM Spring 2025"),
          Competition.new(start_date: Date.new(2025, 5, 1), display_name: "MIBM Fall 2025"),
          Competition.new(start_date: Date.new(2024, 5, 1), display_name: "MIBM 2024")
        ]
        render(Leaderboard::OtherCompetitionLinks::Component.new(
          competitions:,
          current_competition: competitions[1]
        ))
      end

      private

      def sample_competitions
        %w[2026 2025 2024].map { |y| Competition.new(start_date: Date.new(y.to_i, 5, 1), display_name: "MIBM #{y}") }
      end
    end
  end
end

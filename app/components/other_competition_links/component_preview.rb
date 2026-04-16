# frozen_string_literal: true

module OtherCompetitionLinks
  class ComponentPreview < ApplicationComponentPreview
    def default
      render(OtherCompetitionLinks::Component.new(
        competitions: sample_competitions,
        current_year: 2025
      ))
    end

    def original_view
      render(OtherCompetitionLinks::Component.new(
        competitions: sample_competitions,
        current_year: 2024,
        original_view: true
      ))
    end

    private

    def sample_competitions
      %w[2024 2025 2026].map { |y| Competition.new(start_date: Date.new(y.to_i, 5, 1), display_name: "MIBM #{y}") }
    end
  end
end

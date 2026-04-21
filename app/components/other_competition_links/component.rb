# frozen_string_literal: true

module OtherCompetitionLinks
  class Component < ApplicationComponent
    CURRENT_TITLE = "You're looking at it"

    def initialize(competitions:, current_competition:, original_view: false)
      @competitions = competitions
      @current_competition = current_competition
      @original_view = original_view
    end

    private

    def current_competition?(competition)
      @current_competition == competition
    end

    def show_display_name?(competition)
      multi_entry_years.include?(competition.year)
    end

    def multi_entry_years
      @multi_entry_years ||= @competitions.group_by(&:year).select { |_, cs| cs.size > 1 }.keys
    end
  end
end

# frozen_string_literal: true

module OtherCompetitionLinks
  class Component < ApplicationComponent
    CURRENT_TITLE = "You're looking at it"

    def initialize(competitions:, current_year:, original_view: false)
      @competitions = competitions
      @current_year = current_year
      @original_view = original_view
    end

    private

    def current_competition?(competition)
      competition.year == @current_year
    end
  end
end

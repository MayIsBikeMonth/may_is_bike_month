# frozen_string_literal: true

module CompetitionTable::TotalCell
  class ComponentPreview < ApplicationComponentPreview
    def default
      render(CompetitionTable::TotalCell::Component.new(competition_user: preview_competition_user))
    end
  end
end

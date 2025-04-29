# frozen_string_literal: true

module CompetitionTable::TotalCell
  class Component < ApplicationComponent
    def initialize(competition_user: nil, initial_unit: DEFAULT_INITIAL_UNIT)
      @competition_user = competition_user
      @initial_unit = initial_unit
    end
  end
end

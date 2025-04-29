# frozen_string_literal: true

module CompetitionTable::TableHeader
  class Component < ApplicationComponent
    def initialize(competition:, initial_unit: DEFAULT_INITIAL_UNIT)
      @competition = competition
      @initial_unit = initial_unit
    end
  end
end

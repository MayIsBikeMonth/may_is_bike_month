# frozen_string_literal: true

module Punchcard::Footer
  class Component < ApplicationComponent
    def initialize(updated_at:, previous_competitions: [])
      @updated_at = updated_at
      @previous_competitions = previous_competitions
    end
  end
end

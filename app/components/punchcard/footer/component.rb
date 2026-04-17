# frozen_string_literal: true

module Punchcard::Footer
  class Component < ApplicationComponent
    def initialize(updated_at:, competitions: [], current_year: nil)
      @updated_at = updated_at
      @competitions = competitions
      @current_year = current_year
    end
  end
end

# frozen_string_literal: true

module Punchcard::Axis
  class Component < ApplicationComponent
    def initialize(period_dates:)
      @period_dates = period_dates
    end
  end
end

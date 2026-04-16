# frozen_string_literal: true

module Punchcard::Axis
  class Component < ApplicationComponent
    def initialize(period_dates:)
      @period_dates = period_dates
    end

    private

    def day_entries
      @period_dates.map { |date| {day: date.day, weekend: date.saturday? || date.sunday?} }
    end
  end
end

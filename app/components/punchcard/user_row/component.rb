# frozen_string_literal: true

module Punchcard::UserRow
  class Component < ApplicationComponent
    def initialize(competition_user:, competition:, rank:, period_date_strings:, user_daily:)
      @competition_user = competition_user
      @competition = competition
      @rank = rank
      @period_date_strings = period_date_strings
      @user_daily = user_daily
    end

    private

    def distance_meters_on(date_string)
      @user_daily.dig(date_string, :distance_meters).to_f
    end

    def days_count
      @competition_user.activity_dates.count
    end

    def total_days
      @period_date_strings.count
    end

    def total_miles
      meters_to_miles(@competition_user.distance_meters)
    end

    def total_km
      @competition_user.distance_meters / 1000.0
    end

    def total_feet
      meters_to_feet(@competition_user.elevation_meters)
    end

    def total_meters
      @competition_user.elevation_meters
    end

    def strava_url
      @competition_user.user.strava_user_url
    end
  end
end

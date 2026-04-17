# frozen_string_literal: true

module Punchcard::UserRow
  class Component < ApplicationComponent
    STRAVA_SVG_PATH = "M15.387 17.944l-2.089-4.116h-3.065L15.387 24l5.15-10.172h-3.066m-7.008-5.599l2.836 5.598h4.172L10.463 0l-7 13.828h4.169"

    def initialize(competition_user:, competition:, rank:, period_date_strings:, user_daily:)
      @competition_user = competition_user
      @competition = competition
      @rank = rank
      @period_date_strings = period_date_strings
      @user_daily = user_daily
    end

    private

    def cells
      @period_date_strings.map do |date_string|
        distance_meters = @user_daily.dig(date_string, :distance_meters).to_f
        date = Date.parse(date_string)
        level = Punchcard::Wrapper::Component.level_for(distance_meters, competition: @competition)
        {
          level:,
          weekend: date.saturday? || date.sunday?,
          century: Punchcard::Wrapper::Component.century?(distance_meters),
          title: level ? "#{date_string}: #{meters_to_miles(distance_meters).round(1)} mi" : "no rides"
        }
      end
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

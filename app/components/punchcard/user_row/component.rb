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

    def user_slug
      user = @competition_user.user
      user.strava_username.presence || Slugifyer.slugify(user.display_name).presence || user.id.to_s
    end

    def activities_by_date
      @activities_by_date ||= @competition_user.competition_activities_included
        .sort_by { |a| a.start_at || Time.at(0) }
        .each_with_object({}) do |activity, hash|
          activity.activity_dates_strings.each do |date_string|
            (hash[date_string] ||= []) << activity
          end
        end
    end
  end
end

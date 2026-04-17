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

    def distance_meters = @competition_user.distance_meters

    def elevation_meters = @competition_user.elevation_meters

    def strava_url
      @competition_user.user.strava_user_url
    end

    def user_slug
      @user_slug ||= @competition_user.user.slug
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

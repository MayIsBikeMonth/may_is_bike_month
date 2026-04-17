# frozen_string_literal: true

module Punchcard::Wrapper
  class Component < ApplicationComponent
    LEVEL_THRESHOLDS_MILES = {2 => 9, 3 => 20, 4 => 40, 5 => 62.14}.freeze

    def self.daily_metrics(competition_user)
      activities = competition_user.competition_activities_included
      Hash.new { |hash, key| hash[key] = {distance_meters: 0.0, elevation_meters: 0.0} }.tap do |result|
        activities.each do |activity|
          activity.activity_dates_strings.each do |date_string|
            result[date_string][:distance_meters] += activity.distance_meters.to_f
            result[date_string][:elevation_meters] += activity.elevation_meters.to_f
          end
        end
      end
    end

    def self.level_thresholds(competition)
      {1 => meters_to_miles(competition.daily_distance_requirement).ceil}.merge(LEVEL_THRESHOLDS_MILES)
    end

    def initialize(competition:, competition_users:, updated_at: nil, competitions: [])
      @competition = competition
      @competition_users = competition_users
      @updated_at = updated_at
      @competitions = competitions
    end
  end
end

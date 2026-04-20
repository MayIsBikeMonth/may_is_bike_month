# frozen_string_literal: true

module Punchcard::Wrapper
  class Component < ApplicationComponent
    include ActionView::RecordIdentifier

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
      {1 => meters_to_miles(competition.daily_distance_requirement)}.merge(LEVEL_THRESHOLDS_MILES)
    end

    def self.broadcast_refresh_current!
      competition = Competition.current
      return unless competition

      competition_users = competition.competition_users_included
        .includes(:user, :competition_activities_included).score_ordered
      new(
        competition:,
        competition_users:,
        updated_at: StravaRequest.most_recent_update,
        competitions: Competition.start_ordered_desc
      ).broadcast_refresh!
    end

    def initialize(competition:, competition_users:, updated_at: nil, competitions: [])
      @competition = competition
      @competition_users = competition_users
      @updated_at = updated_at
      @competitions = competitions
    end

    def id
      dom_id(@competition, :punchcard_wrapper)
    end

    def broadcast_channel
      [@competition, :punchcard_wrapper]
    end

    def broadcast_refresh!
      Turbo::StreamsChannel.broadcast_replace_to(
        broadcast_channel,
        target: id,
        renderable: self,
        layout: false
      )
    end
  end
end

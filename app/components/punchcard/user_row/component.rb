# frozen_string_literal: true

module Punchcard
  module UserRow
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

      def upcoming?(date_string)
        return true if date_string > current_date_string
        # Today defaults to "upcoming" (hidden) so we don't show a premature
        # "no rides" dot on a day that isn't over — but render it as a punch
        # once the user has activity on it.
        date_string == current_date_string && distance_meters_on(date_string).zero?
      end

      def current_date_string
        @current_date_string ||= @competition_user.current_date.to_s
      end

      def days_count
        @competition_user.activity_dates.count
      end

      def days_so_far
        last = [@competition_user.current_date, @competition.end_date].min
        return 0 if last < @competition.start_date
        (@competition.start_date..last).count
      end

      def distance_meters = @competition_user.distance_meters

      def elevation_meters = @competition_user.elevation_meters

      def strava_url
        @competition_user.user.strava_user_url
      end

      def user_slug
        @user_slug ||= @competition_user.user.slug
      end

      def start_col
        @start_col ||= (@competition.start_date.wday - 1) % 7 + 1
      end
    end
  end
end

# frozen_string_literal: true

module Punchcard
  module Body
    class Component < ApplicationComponent
      def initialize(competition:, competition_users:, updated_at: nil, competitions: [])
        @competition = competition
        @competition_users = competition_users
        @updated_at = updated_at
        @competitions = competitions
      end

      private

      def period_dates
        @period_dates ||= (@competition.start_date..@competition.end_date).to_a
      end

      def period_date_strings
        @period_date_strings ||= period_dates.map(&:to_s)
      end

      def daily_totals
        @daily_totals ||= period_date_strings.map do |date_string|
          {
            date_string:,
            distance_meters: sum_across_users(:distance_meters, date_string),
            elevation_meters: sum_across_users(:elevation_meters, date_string),
            activity_count: sum_across_users(:activity_count, date_string).to_i
          }
        end
      end

      def sum_across_users(metric, date_string)
        @competition_users.sum { |cu| user_daily(cu).dig(date_string, metric).to_f }
      end

      def user_daily(competition_user)
        (@user_daily ||= {})[competition_user.id] ||=
          Punchcard::Wrapper::Component.daily_metrics(competition_user)
      end

      def total_distance_meters
        @total_distance_meters ||= @competition_users.sum { |cu| cu.distance_meters }
      end

      def total_elevation_meters
        @total_elevation_meters ||= @competition_users.sum { |cu| cu.elevation_meters }
      end

      def everyday_rider_count
        @everyday_rider_count ||= @competition_users.count(&:everyday_rider?)
      end
    end
  end
end

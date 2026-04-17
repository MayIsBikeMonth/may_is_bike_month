# frozen_string_literal: true

module Punchcard::Body
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
          distance_meters: sum_across_users(:distance_meters, date_string),
          elevation_meters: sum_across_users(:elevation_meters, date_string)
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

    def total_miles
      @total_miles ||= @competition_users.sum { |cu| cu.distance_meters } / 1609.344
    end

    def total_feet
      @total_feet ||= @competition_users.sum { |cu| cu.elevation_meters } * 3.28084
    end

    def everyday_rider_count
      @everyday_rider_count ||= @competition_users.count do |cu|
        cu.activity_dates.count >= period_dates.count
      end
    end
  end
end

# frozen_string_literal: true

module Legacy
  module Leaderboard
    class Component < ApplicationComponent
      def initialize(competition:, competition_users:, competitions: [])
        @competition = competition
        @competition_users = competition_users
        @competitions = competitions
      end

      private

      def periods
        @periods ||= @competition.periods
      end

      def period_label(period)
        start_date = Date.parse(period[:start_date])
        end_date = Date.parse(period[:end_date])
        "#{start_date.strftime("%b %-d")}–#{end_date.strftime("%-d")}"
      end

      def period_entries(competition_user)
        stored = competition_user.score_data&.dig("periods") || []
        periods.map do |period|
          stored.find { |p| p["start_date"] == period[:start_date] } ||
            {"distance" => 0, "elevation" => 0}
        end
      end

      def total_distance_meters
        @total_distance_meters ||= @competition_users.sum(&:distance_meters)
      end

      def total_elevation_meters
        @total_elevation_meters ||= @competition_users.sum(&:elevation_meters)
      end

      def activities_by_date(competition_user)
        competition_user.competition_activities_included
          .sort_by { |a| a.start_at || Time.at(0) }
          .each_with_object({}) do |activity, hash|
            activity.activity_dates_strings.each do |date_string|
              (hash[date_string] ||= []) << activity
            end
          end
      end

      def short_date(date_string)
        date_string.delete_prefix("#{@competition.year}-")
      end

      def activity_link(activity)
        link_to(activity.strava_url, target: "_blank", rel: "noopener",
          class: "group cursor-pointer text-purple-500 dark:text-purple-200") do
          safe_join([
            content_tag(:span, activity.display_name, class: "underline decoration-1 group-hover:decoration-2"),
            " ".html_safe,
            content_tag(:span, class: "opacity-60 group-hover:underline") do
              safe_join([
                content_tag(:span, "#{meters_to_miles(activity.distance_meters).round(1)} mi", class: "unit-imperial"),
                content_tag(:span, "#{(activity.distance_meters / 1000.0).round(1)} km", class: "unit-metric hidden")
              ])
            end
          ])
        end
      end
    end
  end
end

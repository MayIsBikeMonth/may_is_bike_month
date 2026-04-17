# frozen_string_literal: true

module Punchcard::UserActivitiesForDate
  class ComponentPreview < ApplicationComponentPreview
    # @!group Activities
    def default
      render_with_template(
        template: "punchcard/user_activities_for_date/component_preview/default",
        locals: {
          dates: [
            {date_string: "2025-05-15", activities: sample_activities, punch_id: "sample-2025-05-15"}
          ]
        }
      )
    end

    def single_activity
      render_with_template(
        template: "punchcard/user_activities_for_date/component_preview/default",
        locals: {
          dates: [
            {date_string: "2025-05-15", activities: [sample_activities.first], punch_id: "sample-2025-05-15"}
          ]
        }
      )
    end

    def multiple_dates
      render_with_template(
        template: "punchcard/user_activities_for_date/component_preview/default",
        locals: {
          dates: [
            {date_string: "2025-05-15", activities: [sample_activities[0]], punch_id: "sample-2025-05-15"},
            {date_string: "2025-05-16", activities: sample_activities[0..1], punch_id: "sample-2025-05-16"},
            {date_string: "2025-05-20", activities: sample_activities, punch_id: "sample-2025-05-20"}
          ]
        }
      )
    end
    # @!endgroup

    private

    def sample_activities
      [
        Struct.new(:display_name, :strava_url, :distance_meters).new(
          "Morning commute", "https://www.strava.com/activities/1", 8_046.72
        ),
        Struct.new(:display_name, :strava_url, :distance_meters).new(
          "Afternoon loop", "https://www.strava.com/activities/2", 16_093.44
        ),
        Struct.new(:display_name, :strava_url, :distance_meters).new(
          "Evening spin", "https://www.strava.com/activities/3", 4_023.36
        )
      ]
    end
  end
end

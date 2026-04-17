# frozen_string_literal: true

module Punchcard::UserActivitiesForDate
  class Component < ApplicationComponent
    def initialize(date_string:, activities:, punch_id:, competition_year:)
      @date_string = date_string
      @activities = activities
      @punch_id = punch_id
      @competition_year = competition_year
    end

    private

    def short_date
      @date_string.delete_prefix("#{@competition_year}-")
    end

    def activities_html
      safe_join(@activities.map { |activity| activity_html(activity) }, ", ")
    end

    def activity_html(activity)
      link_to(activity.strava_url, target: "_blank", rel: "noopener", class: "twlink group") do
        safe_join([
          activity.display_name,
          " ".html_safe,
          content_tag(:span, class: "no-underline opacity-60 group-hover:underline") do
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

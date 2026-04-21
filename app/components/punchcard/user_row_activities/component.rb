# frozen_string_literal: true

module Punchcard
  module UserRowActivities
    class Component < ApplicationComponent
      def initialize(competition_user:, competition:)
        @competition_user = competition_user
        @competition = competition
      end

      def call
        tag.div(class: container_class) do
          safe_join(activities_by_date.map { |date_string, activities|
            render(Punchcard::UserActivitiesForDate::Component.new(
              date_string:,
              activities:,
              punch_id: "#{user_slug}-#{date_string}",
              competition_year: @competition.year
            ))
          })
        end
      end

      private

      def container_class
        "punch-activities-container hidden! columns-1 md:columns-2 lg:columns-3 " \
          "[column-gap:1.5rem] mb-2 text-[12px] mt-2 max-lg:mt-4"
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
end

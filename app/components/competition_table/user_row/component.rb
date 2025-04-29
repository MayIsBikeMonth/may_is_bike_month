# frozen_string_literal: true

module CompetitionTable::UserRow
  class Component < ApplicationComponent
    def initialize(competition_user:, initial_unit: DEFAULT_INITIAL_UNIT, activities_expanded: false)
      @competition_user = competition_user
      @initial_unit = initial_unit
      @activities_expanded = activities_expanded
    end

    private

    def competition_activity_display(competition_activity)
      content_tag(:span) do
        concat(competition_activity.display_name)
        if competition_activity.manual_entry? && competition_activity.entered_after_competition_ended?
          concat(" ")
          concat(content_tag(:strong, "?", title: "ignored, manual entry after competition ended"))
        end
      end
    end

    def activity_dates_display(activity_dates)
      if activity_dates.count > 1
        short_date_string_gsub(activity_dates.first)
      else
        activity_dates.map { |d| short_date_string_gsub(d) }.to_sentence
      end
    end

    def short_date_string_gsub(activity_date)
      activity_date.gsub(/\A\d\d\d\d-/, "")
    end
  end
end

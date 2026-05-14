# frozen_string_literal: true

module Leaderboard
  module PunchcardUserPunch
    class Component < ApplicationComponent
      def initialize(date_string:, distance_meters:, competition:, punch_id: nil, user_slug: nil, upcoming: false)
        @date_string = date_string
        @distance_meters = distance_meters
        @competition = competition
        @punch_id = punch_id || date_string
        @user_slug = user_slug
        @upcoming = upcoming
      end

      def call
        return tag.span if @upcoming

        render(UI::Tooltip::Component.new(text: tooltip_imperial)) do |tooltip|
          tooltip.with_body { tooltip_body }
          tooltip.with_tooltip_button(**button_attrs)
        end
      end

      private

      def button_attrs
        return {class: "punchcard-cell"} unless level

        data = {
          action: "click->punch#toggle",
          "punch-target": "punch",
          "punch-id": @punch_id,
          date: @date_string,
          l: level
        }
        data["user-slug"] = @user_slug if @user_slug
        data[:century] = true if century?
        {class: button_class, "aria-pressed": "false", data:}
      end

      def button_class
        "punchcard-cell cursor-pointer outline-none transition-shadow " \
          "hover:ring-1 hover:ring-purple-300 dark:hover:ring-purple-600 " \
          "focus-visible:ring-[2px] focus-visible:ring-purple-400 dark:focus-visible:ring-purple-500 " \
          "aria-pressed:shadow-[0_3px_0_0_var(--color-purple-900)] " \
          "dark:aria-pressed:shadow-[0_3px_0_0_var(--color-purple-0)]"
      end

      def miles
        @miles ||= meters_to_miles(@distance_meters)
      end

      def level
        @level ||= begin
          thresholds = Leaderboard::PunchcardWrapper::Component.level_thresholds(@competition)
          thresholds.keys.rfind { |l| miles >= thresholds[l] }
        end
      end

      def century?
        miles >= 100
      end

      def tooltip_body
        safe_join([
          tag.span(tooltip_imperial, class: "unit-imperial"),
          tag.span(tooltip_metric, class: "unit-metric hidden")
        ])
      end

      def tooltip_imperial
        return "#{date_label}: #{miles.round(1)} mi" if level
        threshold = meters_to_miles(@competition.daily_distance_requirement).round
        "#{date_label}: didn't ride #{threshold} miles"
      end

      def tooltip_metric
        return "#{date_label}: #{(@distance_meters / 1000.0).round(1)} km" if level
        threshold = (@competition.daily_distance_requirement / 1000.0).round
        "#{date_label}: didn't ride #{threshold} km"
      end

      def date_label
        @date_label ||= Date.parse(@date_string).strftime("%b %-d")
      end
    end
  end
end

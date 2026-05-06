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

        render(UI::Tooltip::Component.new(text: tooltip_text)) do |tooltip|
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

      def tooltip_text
        "#{Date.parse(@date_string).strftime("%b %-d")}: #{level ? "#{miles.round(1)} mi" : "no rides"}"
      end
    end
  end
end

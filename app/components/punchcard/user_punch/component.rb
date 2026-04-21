# frozen_string_literal: true

module Punchcard
  module UserPunch
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
        return tag.span(class: "punchcard-cell", title:) unless level

        data = {
          action: "click->punch#toggle",
          "punch-target": "punch",
          "punch-id": @punch_id,
          date: @date_string,
          l: level
        }
        data["user-slug"] = @user_slug if @user_slug
        data[:century] = true if century?
        tag.button(
          "",
          type: "button",
          class: button_class,
          title:,
          "aria-pressed": "false",
          data:
        )
      end

      private

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
          thresholds = Punchcard::Wrapper::Component.level_thresholds(@competition)
          thresholds.keys.rfind { |l| miles >= thresholds[l] }
        end
      end

      def century?
        miles >= 100
      end

      def title
        level ? "#{@date_string}: #{miles.round(1)} mi" : "no rides"
      end
    end
  end
end

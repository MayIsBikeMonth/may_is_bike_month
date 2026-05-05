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
        return no_ride_cell unless level

        ride_cell
      end

      private

      def ride_cell
        data = {
          controller: "ui--tooltip",
          action: "click->punch#toggle #{tooltip_actions}",
          "punch-target": "punch",
          "punch-id": @punch_id,
          "ui--tooltip-target": "trigger",
          date: @date_string,
          l: level
        }
        data["user-slug"] = @user_slug if @user_slug
        data[:century] = true if century?
        tag.button(
          type: "button",
          class: button_class,
          "aria-pressed": "false",
          "aria-describedby": tooltip_id,
          data:
        ) { tooltip_span }
      end

      def no_ride_cell
        tag.span(
          class: "punchcard-cell",
          "aria-describedby": tooltip_id,
          data: {
            controller: "ui--tooltip",
            "ui--tooltip-target": "trigger",
            action: tooltip_actions
          }
        ) { tooltip_span }
      end

      def tooltip_actions
        "mouseenter->ui--tooltip#showOnHover mouseleave->ui--tooltip#hideOnHover " \
          "focusin->ui--tooltip#showOnFocus focusout->ui--tooltip#hideOnFocusout"
      end

      def tooltip_span
        tag.span(
          tooltip_text,
          role: "tooltip",
          id: tooltip_id,
          data: {"ui--tooltip-target": "tooltip"},
          class: "hidden pointer-events-none whitespace-nowrap rounded bg-purple-900 px-2 " \
            "py-1 text-xs text-white border border-purple-400 z-50 " \
            "dark:border-purple-300 dark:bg-purple-100 dark:text-purple-900"
        )
      end

      def tooltip_id
        @tooltip_id ||= "punch-tooltip-#{SecureRandom.hex(4)}"
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

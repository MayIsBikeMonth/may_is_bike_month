# frozen_string_literal: true

module Leaderboard
  module PunchcardUserPunch
    class ComponentPreview < ApplicationComponentPreview
      # @!group Punches
      def level_1 = render_punch(4)
      def level_2 = render_punch(12)
      def level_3 = render_punch(25)
      def level_4 = render_punch(50)
      def level_5 = render_punch(70)
      def century = render_punch(110)
      def no_ride = render_punch(0)
      # @!endgroup

      private

      def render_punch(miles)
        render_with_template(
          template: "punchcard/user_punch/component_preview/punch",
          locals: {miles:}
        )
      end
    end
  end
end

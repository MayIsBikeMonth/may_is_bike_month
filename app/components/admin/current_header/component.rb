# frozen_string_literal: true

module Admin
  module CurrentHeader
    class Component < ApplicationComponent
      def initialize(viewing:, searchable_competitions:, s_params:, include_competition_select: false, competition_subject: nil, render_period: false)
        @viewing = viewing
        @include_competition_select = include_competition_select
        @s_params = s_params
        @competition_subject = competition_subject
        @searchable_competitions = searchable_competitions
        @render_period = render_period
      end

      def render?
        (header_keys & @s_params.keys).any? || @include_competition_select
      end

      private

      # NOTE: when you add new search_ params here, also add it to hidden_search_fields
      def header_keys
        %w[user_id competition_id]
      end
    end
  end
end

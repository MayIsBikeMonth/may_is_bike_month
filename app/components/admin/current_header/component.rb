# frozen_string_literal: true

module Admin
  module CurrentHeader
    class Component < ApplicationComponent
      def initialize(viewing:, searchable_competitions:, s_params:, pagy:, include_competition_select: false, competition_subject: nil, user_subject: nil, user_param: nil, period: nil, render_chart: false, chart_collection: nil, time_range: nil, time_range_column: "created_at")
        @viewing = viewing
        @include_competition_select = include_competition_select
        @s_params = s_params
        @pagy = pagy
        @competition_subject = competition_subject
        @user_subject = user_subject
        @user_param = user_param
        @searchable_competitions = searchable_competitions
        @period = period
        @render_chart = render_chart
        @chart_collection = chart_collection
        @time_range = time_range
        @time_range_column = time_range_column
      end

      def show_user?
        @user_subject.present? || @user_param.present?
      end

      def title
        "Admin #{@viewing}".titleize
      end

      def chart_toggle_url
        url_for(@s_params.merge(render_chart: !@render_chart))
      end

      def chart_toggle_class
        "twlink #{"active" if @render_chart}"
      end

      def render_chart?
        @render_chart && @chart_collection.present? && @time_range.present?
      end

      def matching_count
        @pagy&.count || 0
      end

      def chart_component
        data = UI::Chart::Component.time_range_counts(collection: @chart_collection, time_range: @time_range, column: @time_range_column)
        UI::Chart::Component.new(series: [{name: @viewing, data:}], time_range: @time_range)
      end
    end
  end
end

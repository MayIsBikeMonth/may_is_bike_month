# frozen_string_literal: true

module SortableTable
  extend ActiveSupport::Concern
  SORT_DIRECTIONS = %w[asc desc].freeze

  included do
    helper_method :sort_column, :sort_direction, :default_column
  end

  def sort_column
    @sort_column ||= sortable_columns.include?(params[:sort]) ? params[:sort] : default_column
  end

  def sort_direction
    @sort_direction ||= SORT_DIRECTIONS.include?(params[:direction]) ? params[:direction] : default_direction
  end

  def permitted_time_range_columns
    %w[created_at updated_at].freeze
  end

  def current_time_range_column
    if permitted_time_range_columns.include?(sort_column)
      sort_column
    else
      permitted_time_range_columns.first
    end
  end

  # So it can be overridden
  def default_direction
    "desc"
  end

  def default_column
    sortable_columns.first
  end
end

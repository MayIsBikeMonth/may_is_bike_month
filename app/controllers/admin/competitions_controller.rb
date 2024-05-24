class Admin::CompetitionsController < Admin::BaseController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]

  def index
    @competitions = searched_competitions
      .reorder("competitions.#{sort_column} #{sort_direction}")
      .includes(:competition_users)
  end

  private

  def sortable_columns
    %w[start_date end_date created_at updated_at display_name]
  end

  def latest_period_date
    Time.current + 1.year
  end

  def searched_competitions
    @time_range_column = sort_column if %w[start_date end_date created_at updated_at].include?(sort_column)
    @time_range_column ||= 'start_date'
    Competition.where(@time_range_column => @time_range)
  end
end

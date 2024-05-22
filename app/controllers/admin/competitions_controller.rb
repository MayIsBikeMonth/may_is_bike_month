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
    %w[created_at updated_at email username]
  end

  def searched_competitions
    Competition.where(@created_at => @time_range)
  end
end

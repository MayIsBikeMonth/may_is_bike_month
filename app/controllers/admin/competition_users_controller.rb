class Admin::CompetitionUsersController < Admin::BaseController
  # include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]
  before_action :find_competition_user, except: [:index]

  def index
    @competition_users = searched_competition_users
      .reorder("competition_users.#{sort_column} #{sort_direction}")
      .includes(:competition, :competition_activities)
  end

  def edit
  end

  def update
    if @competition_user.update(permitted_params)
      flash[:success] = "User updated"
      redirect_to(admin_competition_users_path, status: :see_other)
    else
      render :edit, status: :see_other
    end
  end

  private

  def sortable_columns
    %w[created_at updated_at email username]
  end

  def searched_competition_users
    competition_users = CompetitionUser
    if competition_subject.present?
      competition_users = competition_users.where(competition_id: competition_subject.id)
    end

    @time_range_column = (sort_column == "updated_at") ? "updated_at" : "created_at"
    competition_users.where(@time_range_column => @time_range)
  end

  def update_included_param
    params.permit(:update_included)
  end

  def permitted_params
    params.require(:competition_user).permit(:display_name, :included_in_competition)
  end

  def find_competition_user
    @competition_user = CompetitionUser.find(params[:id])
  end
end

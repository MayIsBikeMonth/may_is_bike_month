class Admin::CompetitionUsersController < Admin::BaseController
  include TranzitoUtils::SortableTable
  before_action :set_period, only: [:index]
  before_action :find_competition_user, except: [:index]

  def index
    @competition_users = searched_competition_users
      .reorder("competition_users.#{sort_column} #{sort_direction}")
  end

  def edit
  end

  def update
    if @competition_user.update(permitted_params)
      flash[:success] = "User updated"
      redirect_to edit_admin_user_path(@competition_user), status: :see_other
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

    @time_range_column = (sort_column == "updated_at") ? "updated_at" : "created_at"
    competition_users.where(@time_range_column => @time_range)
  end

  def permitted_params
    params.require(:competition_user).permit(:username, :role)
  end

  def find_user
    @competition_user = CompetitionUser.friendly_find!(params[:id])
  end
end
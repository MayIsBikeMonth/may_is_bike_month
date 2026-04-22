module Admin
  class UsersController < Admin::BaseController
    include Binxtils::SortableTable

    before_action :find_user, except: [:index]

    def index
      @matching_users = searched_users
      @users = @matching_users
        .reorder("users.#{sort_column} #{sort_direction}")
        .includes(:competition_users)
    end

    def edit
      @competition_users = @user.competition_users
        .includes(:competition, :competition_activities)
        .start_ordered_desc
    end

    def update
      if @user.update(permitted_params)
        flash[:success] = "User updated"
        redirect_to(admin_users_path, status: :see_other)
      else
        @competition_users = @user.competition_users
          .includes(:competition, :competition_activities)
          .start_ordered_desc
        render(:edit, status: :see_other)
      end
    end

    private

    def sortable_columns
      %w[created_at last_sign_in_at updated_at display_name role sign_in_count]
    end

    def searched_users
      @time_range_column = %w[last_sign_in_at updated_at].include?(sort_column) ? sort_column : "created_at"
      User.where(@time_range_column => @time_range)
    end

    def permitted_params
      params.require(:user).permit(:display_name)
    end

    def find_user
      @user = User.friendly_find!(params[:id])
    end
  end
end

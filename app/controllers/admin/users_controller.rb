module Admin
  class UsersController < Admin::BaseController
    include Binxtils::SortableTable

    def index
      @matching_users = searched_users
      @users = @matching_users
        .reorder("users.#{sort_column} #{sort_direction}")
        .includes(:competition_users)
    end

    private

    def sortable_columns
      %w[created_at last_sign_in_at updated_at display_name role sign_in_count]
    end

    def searched_users
      @time_range_column = %w[last_sign_in_at updated_at].include?(sort_column) ? sort_column : "created_at"
      User.where(@time_range_column => @time_range)
    end
  end
end

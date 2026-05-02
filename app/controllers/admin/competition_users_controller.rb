module Admin
  class CompetitionUsersController < Admin::BaseController
    include Binxtils::SortableTable

    before_action :find_competition_user, except: %i[index enqueue_update_job]

    def index
      @matching_competition_users = searched_competition_users
      @pagy, @competition_users = pagy(:countish,
        @matching_competition_users
          .reorder("competition_users.#{sort_column} #{sort_direction}")
          .includes(:competition, :competition_activities),
        limit: per_page, page:)
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

    def enqueue_update_job
      if UpdateCompetitionUserJob.enqueue_current
        flash[:success] = "UpdateCompetitionUserJob enqueued"
      else
        flash[:error] = "No current competition"
      end
      redirect_back(fallback_location: admin_competition_users_path, status: :see_other)
    end

    private

    def sortable_columns
      %w[updated_at created_at email username]
    end

    def competition_subject
      return @competition_subject if defined?(@competition_subject)

      competition_params = params.permit(:competition_id, :search_competition_id)
      competition_id = competition_params[:competition_id].presence || competition_params[:search_competition_id].presence
      @competition_subject = if competition_id == "all"
        nil
      elsif competition_id.present?
        Competition.friendly_find(competition_id)
      else
        Competition.current
      end
    end

    def searched_competition_users
      competition_users = CompetitionUser
      if competition_subject.present?
        competition_users = competition_users.where(competition_id: competition_subject.id)
      end
      if user_subject.present?
        competition_users = competition_users.where(user_id: user_subject.id)
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
end

module Admin
  class CompetitionActivitiesController < Admin::BaseController
    include Binxtils::SortableTable

    helper_method :competition_user_subject, :show_exclusion_reason?

    def show_exclusion_reason?
      return @show_exclusion_reason if defined?(@show_exclusion_reason)
      @show_exclusion_reason = Binxtils::InputNormalizer.boolean(params[:search_show_exclusion_reason])
    end

    def index
      @matching_competition_activities = searched_competition_activities
      @pagy, @competition_activities = pagy(:countish,
        @matching_competition_activities
          .reorder("competition_activities.#{sort_column} #{sort_direction}")
          .includes(competition_user: %i[user competition]),
        limit: per_page, page:)
    end

    private

    def sortable_columns
      %w[created_at updated_at start_at distance_meters competition_user_id included_in_competition]
    end

    def competition_user_subject
      return @competition_user_subject if defined?(@competition_user_subject)

      cu_id = params.permit(:search_competition_user_id)[:search_competition_user_id]
      @competition_user_subject = cu_id.present? ? CompetitionUser.find_by(id: cu_id) : nil
    end

    def competition_subject
      return @competition_subject if defined?(@competition_subject)

      return @competition_subject = competition_user_subject.competition if competition_user_subject.present?

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

    def searched_competition_activities
      activities = CompetitionActivity
      if competition_user_subject.present?
        activities = activities.where(competition_user_id: competition_user_subject.id)
      elsif competition_subject.present?
        activities = activities.joins(:competition_user)
          .where(competition_users: {competition_id: competition_subject.id})
      end
      if user_subject.present?
        activities = activities.joins(:competition_user)
          .where(competition_users: {user_id: user_subject.id})
      end

      @time_range_column = (sort_column == "updated_at") ? "updated_at" : "created_at"
      activities.where("competition_activities.#{@time_range_column}" => @time_range)
    end
  end
end

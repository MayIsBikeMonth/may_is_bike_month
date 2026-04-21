module Admin
  class StravaRequestsController < Admin::BaseController
    include Binxtils::SortableTable

    def index
      @matching_strava_requests = searched_strava_requests
      @strava_requests = @matching_strava_requests
        .reorder("strava_requests.#{sort_column} #{sort_direction}")
        .includes(:user)
        .limit(100)
    end

    private

    def sortable_columns
      %w[created_at updated_at status kind user_id]
    end

    def searched_strava_requests
      strava_requests = StravaRequest
      if user_subject.present?
        strava_requests = strava_requests.where(user_id: user_subject.id)
      end
      strava_requests.where(created_at: @time_range)
    end
  end
end

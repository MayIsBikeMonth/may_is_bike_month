class ProcessStravaWebhookJob < ApplicationJob
  sidekiq_options retry: 1

  def perform(strava_request_id)
    strava_request = StravaRequest.find(strava_request_id)
    return unless strava_request.incoming_webhook?

    params = strava_request.parameters
    user = strava_request.user

    case params["object_type"]
    when "activity" then handle_activity(user, params)
    when "athlete" then handle_athlete(user, params)
    end
  end

  private

  def handle_activity(user, params)
    if params["aspect_type"] == "delete"
      CompetitionActivity.joins(:competition_user)
        .where(competition_users: {user_id: user.id}, strava_id: params["object_id"].to_s)
        .destroy_all
    else
      competition_user = user.competition_users.current_competition.last
      UpdateCompetitionUserJob.perform_async(competition_user.id) if competition_user
    end
  end

  def handle_athlete(user, params)
    user.update(strava_auth: {}) if params.dig("updates", "authorized") == "false"
  end
end

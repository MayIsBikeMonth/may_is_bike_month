class UpdateCompetitionUserJob < ApplicationJob
  sidekiq_options retry: 1

  def perform(id)
    competition_user = CompetitionUser.find(id)
    if competition_user.excluded_from_competition?
      # Added this constraint, because if "included_in_competition" changes,
      # it doesn't correctly re-enqueue updating
      raise "Competition user isn't included in competition!"
    end
    return unless User.valid_strava_auth?(competition_user.user.strava_auth)
    StravaRequest.update_competition_user_activities(competition_user)
    competition_user.reload.update_score_data!
    Leaderboard::PunchcardWrapper::Component.broadcast_refresh_current!
  end
end

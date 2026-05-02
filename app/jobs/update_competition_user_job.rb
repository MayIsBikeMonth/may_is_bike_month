class UpdateCompetitionUserJob < ApplicationJob
  sidekiq_options retry: 1

  def self.enqueue_current
    competition = Competition.current
    return false unless competition.present?

    competition.create_competition_users

    # If we're over the rate limit, don't enqueue more jobs
    return true if StravaRequest.over_rate_limit?

    # Maybe this should enqueue any without a recent request?
    CompetitionUser.included_in_current_competition.pluck(:id)
      .each { |id| UpdateCompetitionUserJob.perform_async(id) }
  end

  def perform(id = nil)
    return self.class.enqueue_current if id.nil?

    competition_user = CompetitionUser.find(id)
    return unless competition_user.included_in_competition? &&
      User.valid_strava_auth?(competition_user.user.strava_auth)

    StravaRequest.update_competition_user_activities(competition_user)
    competition_user.reload.update_score_data!
    Leaderboard::PunchcardWrapper::Component.broadcast_refresh_current!
  end
end

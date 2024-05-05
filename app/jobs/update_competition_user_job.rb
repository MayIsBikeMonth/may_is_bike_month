class UpdateCompetitionUserJob < ApplicationJob
  sidekiq_options retry: 1

  def self.enqueue_current
    competition = Competition.current
    return false unless competition.present?

    competition.create_competition_users

    # If an update isn't due, don't enqueue more jobs
    return true unless StravaRequest.update_due?

    # Maybe this should enqueue any without a recent request?
    CompetitionUser.included_in_current_competition.pluck(:id)
      .each { |id| UpdateCompetitionUserJob.perform_async(id) }
  end

  def perform(id)
    competition_user = CompetitionUser.find(id)
    if competition_user.excluded_from_competition?
      # Added this constraint, because if "included_in_competition" changes,
      # it doesn't correctly re-enqueue updating
      raise "Competition user isn't included in competition!"
    end
    StravaRequest.update_competition_user_activities(competition_user)
    competition_user.reload.update_score_data!
  end
end

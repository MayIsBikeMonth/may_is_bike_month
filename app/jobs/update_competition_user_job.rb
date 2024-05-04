class UpdateCompetitionUserJob < ApplicationJob
  sidekiq_options retry: 1

  def self.enqueue_current
    competition = Competition.current
    return false unless competition.present?
    competition.create_competition_users
    competition.competition_users.pluck(:id)
      .each { |id| UpdateCompetitionUserJob.perform_async(id) }
  end

  def perform(id)
    competition_user = CompetitionUser.find(id)
    StravaRequest.update_competition_user_activities(competition_user)
    competition_user.reload.update_score_data!
  end
end

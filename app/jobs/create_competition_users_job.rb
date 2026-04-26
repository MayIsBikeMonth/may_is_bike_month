class CreateCompetitionUsersJob < ApplicationJob
  sidekiq_options retry: 1

  def perform(competition_id)
    Competition.find(competition_id).create_competition_users
  end
end

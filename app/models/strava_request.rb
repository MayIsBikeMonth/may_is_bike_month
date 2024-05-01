# == Schema Information
#
# Table name: strava_requests
#
#  id             :bigint           not null, primary key
#  error_response :jsonb
#  kind           :integer
#  parameters     :jsonb
#  status         :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  user_id        :bigint
#
class StravaRequest < ApplicationRecord
  UPDATE_DELAY = 60
  KIND_ENUM = {get_activities: 0, get_athlete: 1}
  belongs_to :user

  enum kind: KIND_ENUM

  scope :successful, -> { where(status: 201) }

  class << self
    def most_recent_update
      order(:created_at).last&.pick(:created_at)
    end

    def update_due?
      updated_at = most_recent_update
      updated_at.blank? || updated_at < (Time.current - UPDATE_DELAY)
    end

    def update_competition_user_activities(competition_user)
      activities = fetch_user_activities_for_competition(user: competition_user.user,
        parameters: parameters_for_competition_activities(competition_user.competition))

    end

    private

    def parameters_for_competition_activities(competition)
      {
        "before" => competition.end_date + 2.days,
        "after" => competition.start_date - 2.days,
        "per_page" => "100"
      }
    end

    def fetch_user_activities(user:, parameters: {})
      StravaIntegration.get_activities(user.active_strava_token, parameters:)
    end
  end
end

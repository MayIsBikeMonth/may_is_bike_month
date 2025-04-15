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
  KIND_ENUM = {get_activities: 0, get_athlete: 1}.freeze
  SUCCESS_CODES = [200, 201].freeze

  belongs_to :user

  enum :kind, KIND_ENUM

  scope :success_response, -> { where(status: SUCCESS_CODES) }
  scope :error_response, -> { where.not(status: SUCCESS_CODES) }

  class << self
    def success_status?(status)
      SUCCESS_CODES.include?(status)
    end

    def most_recent_update
      maximum(:created_at)
    end

    def update_due?
      updated_at = most_recent_update
      updated_at.blank? || updated_at < (Time.current - UPDATE_DELAY)
    end

    def update_competition_user_activities(competition_user)
      record_request_for_user_activities(
        user: competition_user.user,
        parameters: parameters_for_competition_activities(competition_user.competition)
      ).each do |strava_data|
        CompetitionActivity.find_or_create_if_valid(competition_user:, strava_data:)
      end
    end

    private

    def parameters_for_competition_activities(competition)
      {
        before: (competition.end_date + 2.days).end_of_day.to_i,
        after: (competition.start_date - 2.days).beginning_of_day.to_i,
        per_page: "100"
      }.as_json
    end

    def record_request_for_user_activities(user:, parameters: {})
      result = StravaIntegration.get_activities(user.active_strava_token, parameters:)
      error_response = success_status?(result["status"]) ? nil : result["json"]
      create(user:, parameters:, status: result[:status], kind: :get_activities,
        error_response: error_response)
      error_response ? [] : result["json"]
    end
  end

  def success_response?
    self.class.success_status?(status)
  end

  def error_response?
    !success_response?
  end
end

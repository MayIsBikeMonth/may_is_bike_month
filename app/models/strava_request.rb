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
  KIND_ENUM = {get_activities: 0}
  belongs_to :user

  enum kind: KIND_ENUM

  def self.most_recent_update
    order(:created_at).last.pick(:created_at)
  end

  def self.update_due?
    updated_at = most_recent_update
    updated_at.blank? || updated_at < (Time.current - UPDATE_DELAY)
  end
end

# == Schema Information
#
# Table name: competition_participants
#
#  id                      :bigint           not null, primary key
#  included_activity_types :string
#  included_in_competition :boolean          default(FALSE), not null
#  score                   :integer
#  score_data              :jsonb
#  created_at              :datetime         not null
#  updated_at              :datetime         not null
#  competition_id          :bigint
#  user_id                 :bigint
#
class CompetitionParticipant < ApplicationRecord
  DEFAULT_INCLUDED_ACTIVITY_TYPES = "Ride,Velomobile,Handcycle"
  belongs_to :competition
  belongs_to :user

  before_validation :set_calculated_attributes

  def set_calculated_attributes
    self.included_activity_types = nil if included_activity_types.blank?
  end
end

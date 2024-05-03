# == Schema Information
#
# Table name: competition_users
#
#  id                        :bigint           not null, primary key
#  excluded_from_competition :boolean          default(FALSE), not null
#  included_activity_types   :jsonb
#  score                     :integer
#  score_data                :jsonb
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  competition_id            :bigint
#  user_id                   :bigint
#
class CompetitionUser < ApplicationRecord
  belongs_to :competition
  belongs_to :user

  before_validation :set_calculated_attributes

  def included_in_competition?
    !excluded_from_competition
  end

  def included_activity_type?(activity_type)
    included_activity_types.include?(activity_type)
  end

  def set_calculated_attributes
    self.included_activity_types = if included_activity_types.blank?
      competition&.activity_types || Competition::DEFAULT_ACTIVITY_TYPES
    else
      included_activity_types.map(&:strip).reject(&:blank?)
    end
  end

  def calculated_scoring_data
  end
end

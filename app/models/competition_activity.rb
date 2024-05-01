# == Schema Information
#
# Table name: competition_activities
#
#  id                     :bigint           not null, primary key
#  display_name           :string
#  distance_meters        :float
#  elevation_meters       :float
#  end_date               :date
#  include_in_competition :boolean          default(FALSE), not null
#  moving_seconds         :integer
#  start_at               :datetime
#  start_date             :date
#  strava_data            :jsonb
#  timezone               :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  competition_user_id    :bigint
#  strava_id              :string
#
class CompetitionActivity < ApplicationRecord
  belongs_to :competition_user

  before_validation :set_calculated_attributes

  def set_calculated_attributes
    self.include_in_competition = competition_user.include_in_competition
  end
end

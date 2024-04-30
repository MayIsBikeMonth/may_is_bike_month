# == Schema Information
#
# Table name: competition_activities
#
#  id                         :bigint           not null, primary key
#  display_name               :string
#  distance_meters            :float
#  elevation_meters           :float
#  end_date                   :date
#  include_in_competition     :boolean          default(FALSE), not null
#  moving_seconds             :integer
#  start_at                   :datetime
#  start_date                 :date
#  strava_data                :jsonb
#  timezone                   :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#  competition_participant_id :bigint
#  strava_id                  :string
#
class CompetitionActivity < ApplicationRecord
end

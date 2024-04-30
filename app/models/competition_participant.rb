# == Schema Information
#
# Table name: competition_participants
#
#  id                      :bigint           not null, primary key
#  boolean                 :boolean          default(FALSE), not null
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
end

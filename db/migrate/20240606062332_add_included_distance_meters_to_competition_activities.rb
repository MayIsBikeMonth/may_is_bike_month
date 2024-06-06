class AddIncludedDistanceMetersToCompetitionActivities < ActiveRecord::Migration[7.1]
  def change
    add_column :competition_activities, :included_distance_meters, :float
  end
end

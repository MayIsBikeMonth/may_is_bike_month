class CreateCompetitionActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :competition_activities do |t|
      t.references :competition_user, index: true

      t.string :display_name
      t.float :distance_meters
      t.integer :moving_seconds
      t.float :elevation_meters
      t.date :end_date
      t.datetime :start_at
      t.date :start_date
      t.jsonb :strava_data
      t.string :strava_id
      t.string :timezone
      t.boolean :included_in_competition, default: false, null: false

      t.timestamps
    end
  end
end

class CreateCompetitionActivities < ActiveRecord::Migration[7.1]
  def change
    create_table :competition_activities do |t|
      t.references :competition_user, index: true

      t.string :display_name
      t.float :distance_meters
      t.integer :moving_seconds
      t.float :elevation_meters
      t.string :timezone
      t.datetime :start_at
      t.date :start_date
      t.date :end_date
      t.string :override_activity_dates_string

      t.jsonb :strava_data
      t.string :strava_id

      t.boolean :included_in_competition, default: false, null: false

      t.timestamps
    end
  end
end

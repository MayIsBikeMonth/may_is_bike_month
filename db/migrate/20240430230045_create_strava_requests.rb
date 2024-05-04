class CreateStravaRequests < ActiveRecord::Migration[7.1]
  def change
    create_table :strava_requests do |t|
      t.references :user

      t.jsonb :error_response
      t.jsonb :parameters
      t.integer :status
      t.integer :kind

      t.timestamps
    end
  end
end

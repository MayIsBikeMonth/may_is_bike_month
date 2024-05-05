class RemoveStravaUsernameConstraints < ActiveRecord::Migration[7.1]
  def change
    change_column_null :users, :strava_username, true
    change_column_default :users, :strava_username, nil
    remove_index :users, :strava_username
  end
end

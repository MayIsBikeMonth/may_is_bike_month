class AddCurrentTimezoneToCompetitionUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :competition_users, :current_timezone, :string, default: "America/Los_Angeles", null: false
  end
end

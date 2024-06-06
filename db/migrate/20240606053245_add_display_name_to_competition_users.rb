class AddDisplayNameToCompetitionUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :competition_users, :display_name, :text
  end
end

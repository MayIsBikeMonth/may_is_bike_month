class AddScoreIntegerToCompetitionUsers < ActiveRecord::Migration[7.1]
  def change
    remove_column :competition_users, :score, :float
    add_column :competition_users, :score, :decimal
    add_column :competition_users, :score_integer, :integer
  end
end

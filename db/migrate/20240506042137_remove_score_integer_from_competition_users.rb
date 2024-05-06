class RemoveScoreIntegerFromCompetitionUsers < ActiveRecord::Migration[7.1]
  def change
    # This was added but not actually necessary
    remove_column :competition_users, :score_integer, :integer
  end
end

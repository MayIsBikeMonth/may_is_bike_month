class CreateCompetitionUsers < ActiveRecord::Migration[7.1]
  def change
    create_table :competition_users do |t|
      t.references :competition, index: true
      t.references :user, index: true
      t.boolean :included_in_competition, default: false, null: false
      t.integer :score
      t.jsonb :score_data
      t.jsonb :included_activity_types

      t.timestamps
    end
  end
end

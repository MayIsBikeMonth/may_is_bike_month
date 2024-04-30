class CreateCompetitionParticipants < ActiveRecord::Migration[7.1]
  def change
    create_table :competition_participants do |t|
      t.references :competition, index: true
      t.references :user, index: true
      t.boolean :included_in_competition, :boolean, default: false, null: false
      t.integer :score
      t.jsonb :score_data
      t.string :included_activity_types

      t.timestamps
    end
  end
end

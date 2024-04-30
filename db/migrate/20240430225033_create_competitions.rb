class CreateCompetitions < ActiveRecord::Migration[7.1]
  def change
    create_table :competitions do |t|
      t.string :display_name
      t.string :slug
      t.datetime :end_date
      t.datetime :start_date
      t.boolean :current

      t.timestamps
    end
  end
end

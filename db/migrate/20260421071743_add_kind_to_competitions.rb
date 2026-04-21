class AddKindToCompetitions < ActiveRecord::Migration[8.1]
  def change
    add_column :competitions, :kind, :integer, default: 0, null: false
  end
end

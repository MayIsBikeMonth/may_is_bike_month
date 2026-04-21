class AddLegacyTrackingToCompetitions < ActiveRecord::Migration[8.1]
  def change
    add_column :competitions, :kind, :integer, default: 0, null: false
    add_column :competitions, :legacy_url, :string
  end
end

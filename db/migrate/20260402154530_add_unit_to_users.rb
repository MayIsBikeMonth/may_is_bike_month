class AddUnitToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :unit, :integer, default: 0, null: false
  end
end

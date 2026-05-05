class AddSlugToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :slug, :string
  end
end

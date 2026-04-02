class AddUniqueIndexToCompetitionsSlug < ActiveRecord::Migration[8.1]
  def up
    # Remove duplicate competitions, keeping the oldest one
    duplicates = Competition.group(:slug).having("count(*) > 1").pluck(:slug)
    duplicates.each do |slug|
      ids = Competition.where(slug:).order(:id).pluck(:id)
      Competition.where(id: ids[1..]).destroy_all
    end

    add_index :competitions, :slug, unique: true
  end

  def down
    remove_index :competitions, :slug
  end
end

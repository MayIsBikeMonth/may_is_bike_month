module LegacyUserFinder
  extend Functionable

  def find_or_create(name)
    downcased = name.downcase
    existing = User.where("LOWER(display_name) = ?", downcased)
      .or(User.where("LOWER(display_name) LIKE ?", "#{downcased} %"))
      .or(User.where("LOWER(strava_username) = ?", downcased))
      .first
    return existing if existing

    User.create!(display_name: name, password: Devise.friendly_token[0, 20])
  end
end

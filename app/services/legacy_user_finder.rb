module LegacyUserFinder
  extend Functionable

  def find(name)
    downcased = name.downcase
    User.where("LOWER(display_name) = ?", downcased)
      .or(User.where("LOWER(display_name) LIKE ?", "#{downcased} %"))
      .or(User.where("LOWER(strava_username) = ?", downcased))
      .first
  end

  def find_or_create(name)
    find(name) || User.create!(display_name: name, password: Devise.friendly_token[0, 20])
  end

  def potential_matches(name)
    like = "%#{name.downcase}%"
    User.where("LOWER(display_name) LIKE ? OR LOWER(strava_username) LIKE ?", like, like)
      .pluck(:display_name, :strava_username)
      .map { |display, username| display.presence || username.presence }
      .compact
      .uniq
  end
end

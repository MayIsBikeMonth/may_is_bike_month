PARTICIPANTS_2023 = [
  {name: "Noah", miles: 1833, feet: 104_624},
  {name: "Katya", miles: 1530, feet: 102_752},
  {name: "Jackson", miles: 1048, feet: 70_403},
  {name: "Yvonne", miles: 612, feet: 33_276},
  {name: "Seth", miles: 576, feet: 42_249},
  {name: "Chris", miles: 508, feet: 33_365},
  {name: "Danny", miles: 417, feet: 24_191},
  {name: "Zack", miles: 397, feet: 22_457},
  {name: "Gabby", miles: 374, feet: 0},
  {name: "Sam", miles: 328, feet: 17_630},
  {name: "Brittany", miles: 233, feet: 3_617},
  {name: "Elizabeth", miles: 211, feet: 12_683},
  {name: "Lily B", miles: 137, feet: 0},
  {name: "Ravi", miles: 133, feet: 7_109},
  {name: "Ali", miles: 118, feet: 5_498},
  {name: "Maura", miles: 61, feet: 2_112},
  {name: "Jeremy", miles: 38, feet: 1_789},
  {name: "Gar", miles: 36, feet: 0},
  {name: "Steve", miles: 23, feet: 2_284}
].freeze

MILES_TO_METERS = 1609.344
FEET_TO_METERS = 0.3048

competition = Competition.find_or_create_by!(start_date: Date.new(2023, 5, 1)) do |c|
  c.end_date = Date.new(2023, 5, 31)
  c.display_name = "MIBM 2023"
  c.kind = :legacy
end
competition.update!(kind: :legacy) unless competition.legacy?

def find_or_create_legacy_user(name)
  downcased = name.downcase
  existing = User.where("LOWER(display_name) = ?", downcased)
    .or(User.where("LOWER(display_name) LIKE ?", "#{downcased} %"))
    .or(User.where("LOWER(strava_username) = ?", downcased))
    .first
  return existing if existing

  User.create!(
    display_name: name,
    password: Devise.friendly_token[0, 20]
  )
end

PARTICIPANTS_2023.each do |attrs|
  user = find_or_create_legacy_user(attrs[:name])

  competition_user = CompetitionUser.find_or_initialize_by(competition:, user:)
  competition_user.included_in_competition = true
  competition_user.display_name = attrs[:name]
  competition_user.score_data = {
    dates: [],
    distance: (attrs[:miles] * MILES_TO_METERS).round,
    elevation: (attrs[:feet] * FEET_TO_METERS).round
  }
  competition_user.save!
end

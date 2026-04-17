require "nokogiri"

USERS_2025 = {
  "2430215" => {strava_username: "sethherr", display_name: "seth herr", role: :developer},
  "2557663" => {strava_username: "old_scott", display_name: "Old Scott", role: :basic_user},
  "7645639" => {strava_username: "ali", display_name: "Ali", role: :basic_user}
}.freeze

competition = Competition.find_or_create_by!(start_date: Date.new(2025, 5, 1)) do |c|
  c.end_date = Date.new(2025, 5, 31)
  c.display_name = "MIBM 2025"
end

doc = Nokogiri::HTML.fragment(
  Rails.root.join("app/views/competitions_original/_2025.html.erb").read
)

USERS_2025.each do |strava_id, attrs|
  user = User.find_or_create_by!(strava_id:) do |u|
    u.strava_username = attrs[:strava_username]
    u.display_name = attrs[:display_name]
    u.role = attrs[:role]
  end

  competition_user = CompetitionUser.find_or_create_by!(competition:, user:) do |cu|
    cu.included_in_competition = true
  end

  athlete_link = doc.at_css("a[href='https://www.strava.com/athletes/#{strava_id}']")
  user_row = athlete_link.ancestors("tr").first

  seen = Set.new
  user_row.css("li").each do |li|
    activity_link = li.at_css("a[href*='strava.com/activities/']")
    next unless activity_link

    activity_strava_id = activity_link["href"].split("/").last
    next unless seen.add?(activity_strava_id)

    name = activity_link.at_css("span").text.strip
    date_str = li.children.find { |c| c.name == "span" }.text.strip
    distance_km = li.at_css("span.unit-metric span").text.tr(",", "").to_f

    month, day = date_str.split("-").map(&:to_i)
    date = Date.new(2025, month, day)

    timezone = "(GMT-08:00) America/Los_Angeles"
    local_start = date.strftime("%Y-%m-%dT12:00:00Z")
    utc_start = Time.utc(date.year, date.month, date.day, 19).strftime("%Y-%m-%dT%H:%M:%SZ")

    strava_data = {
      "id" => activity_strava_id.to_i,
      "name" => name,
      "distance" => (distance_km * 1000).round(1),
      "moving_time" => 1800,
      "total_elevation_gain" => 50.0,
      "type" => "Ride",
      "sport_type" => "Ride",
      "start_date" => utc_start,
      "start_date_local" => local_start,
      "timezone" => timezone,
      "visibility" => "everyone"
    }

    activity = competition_user.competition_activities.find_or_initialize_by(strava_id: activity_strava_id)
    activity.update!(strava_data:)
  end

  competition_user.update_score_data!
end

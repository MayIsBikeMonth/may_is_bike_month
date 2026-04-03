User.find_or_create_by!(strava_id: "2430215") do |user|
  user.role = :developer
  user.strava_username = "sethherr"
  user.password = "please12"
end

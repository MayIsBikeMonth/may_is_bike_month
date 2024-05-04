FactoryBot.define do
  factory :competition_activity do
    transient do
      strava_type { "Ride" }
      competition { FactoryBot.create(:competition) }
    end
    competition_user { FactoryBot.create(:competition_user, competition:) }
    sequence(:strava_id) { |n| "11111#{n}" }

    distance_meters { 3611.4 }
    elevation_meters { 200 }
    moving_seconds { 844 }
    start_at { Time.parse("2024-05-03T02:59:12Z") }
    timezone { "America/Los_Angeles" }

    strava_data do
      tz_offset = TranzitoUtils::TimeParser.parse_timezone(timezone).utc_offset
      {
        "id" => strava_id.to_i,
        "name" => "Cool ride",
        "distance" => distance_meters,
        "moving_time" => moving_seconds,
        "total_elevation_gain" => elevation_meters,
        "elapsed_time" => 1632,
        "type" => strava_type,
        "timezone" => "(GMT-08:00) #{timezone}", # data inside parens is ignored
        "start_date" => start_at.utc,
        "start_date_local" => (start_at + tz_offset).utc.rfc3339,
        "visibility" => "everyone"
      }
    end
  end
end

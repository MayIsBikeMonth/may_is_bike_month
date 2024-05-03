FactoryBot.define do
  factory :competition_activity do
    competition_user { FactoryBot.create(:competition_user) }
    sequence(:strava_id) { |n| "11111#{n}" }
    strava_data do
      {
        "strava" => strava_id.to_i,
        "name" => "Cool ride",
        "distance" => 3611.4,
        "moving_time" => 844,
        "elapsed_time" => 1632,
        "type" => "Ride",
        "timezone" => "(GMT-08:00) America/Los_Angeles",
        "start_date" => "2024-05-03T02:59:12Z",
        "start_date_local" => "2024-05-02T19:59:12Z",
        "visibility" => "everyone"
      }
    end
  end
end

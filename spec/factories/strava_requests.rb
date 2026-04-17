FactoryBot.define do
  factory :strava_request do
    user
    kind { :get_activities }
    status { 200 }
    parameters { {"per_page" => "100"} }
  end
end

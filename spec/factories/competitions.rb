FactoryBot.define do
  factory :competition do
    start_date { Time.parse("2024-05-01") }
    display_name { start_date.year }
  end
end

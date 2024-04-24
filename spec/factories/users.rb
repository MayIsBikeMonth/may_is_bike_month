FactoryBot.define do
  factory :user do
    sequence(:strava_username) { |n| "user-#{n}" }
    sequence(:strava_id) { |n| n + 3 }
    password { "some_pass69" }

    strava_info { {strava_username: strava_username} }

    trait :developer_access do
      role { :developer }
    end

    trait :admin_access do
      role { :admin }
    end

    factory :user_developer, traits: [:developer_access]

    factory :user_admin, traits: [:admin_access]
  end
end

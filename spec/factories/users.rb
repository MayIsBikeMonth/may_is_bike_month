FactoryBot.define do
  factory :user do
    sequence(:strava_username) { |n| "user-#{n}" }
    sequence(:strava_id) { |n| n + 3 }
    password { "some_pass69" }

    trait :with_active_strava_token do
      transient { token { "Y" } }

      strava_auth { {token:, refresh_token: "ZZZZZZ", expires_at: (Time.current + 1.day).to_i}.as_json }
    end

    factory :user_with_strava_token, traits: [:with_active_strava_token]

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

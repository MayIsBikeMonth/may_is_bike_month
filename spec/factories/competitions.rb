FactoryBot.define do
  factory :competition do
    start_date { Time.current.beginning_of_month.to_date }
  end
end

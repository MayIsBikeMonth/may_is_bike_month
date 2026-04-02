FactoryBot.define do
  factory :competition do
    sequence(:start_date) { |n| Date.new(2020 + n, 5, 1) }
  end
end

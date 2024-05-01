FactoryBot.define do
  factory :competition_user do
    user { FactoryBot.create(:user) }
    competition { FactoryBot.create(:competition) }
  end
end

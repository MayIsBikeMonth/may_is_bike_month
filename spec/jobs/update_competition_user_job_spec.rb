require "rails_helper"

RSpec.describe UpdateCompetitionUserJob, type: :job do
  let(:instance) { described_class.new }

  describe "perform" do
    let(:user) { FactoryBot.create(:user_with_strava_token, token: "cd775d68780995e60d415b2fd7b6d594a281e3a6") }
    let(:competition_user) { FactoryBot.create(:competition_user, user: user) }
    let(:competition) { competition_user.competition }
    it "updates user score" do
      expect(competition.start_date).to eq Date.parse("2024-5-1")
      expect(competition_user.score_data).to be_blank
      expect(competition_user.score).to eq 0
      VCR.use_cassette("update_competition_user_job", match_requests_on: [:path]) do
        instance.perform(competition_user.id)
      end
      expect(competition_user.reload.score_data).to be_present
      expect(competition_user.score.round(5)).to eq 3.00005
    end
  end
end

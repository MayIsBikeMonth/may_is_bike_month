require "rails_helper"

RSpec.describe User, type: :model do
  describe "factory" do
    let(:user) { FactoryBot.create(:user) }

    it "is valid" do
      expect(user).to be_valid
    end
    context "no strava username" do
      let(:user1) { FactoryBot.create(:user, strava_username: "") }
      let(:user2) { FactoryBot.create(:user, strava_username: "") }
      it "is valid" do
        # There was a pesky db constraint, sanity check
        expect(user1).to be_valid
        expect(user2).to be_valid
      end
    end
    context "user_with_strava_token" do
      let(:user) { FactoryBot.create(:user_with_strava_token) }
      it "is valid" do
        expect(user).to be_valid
        expect(user.strava_auth_needs_refresh?).to be_falsey
        expect(user.active_strava_token).to eq "Y"
      end
    end
  end

  describe "active_strava_token" do
    let(:user) { FactoryBot.create(:user, strava_auth:) }
    let(:strava_auth) { {token: "xxx", refresh_token: "zzz", expires_at:}.as_json }
    let(:expires_at) { (Time.current + 1.hour).to_i }
    it "returns strava_token" do
      expect(User.valid_strava_auth?(user.strava_auth)).to be_truthy
      expect(user.strava_auth_needs_refresh?).to be_falsey
      expect(user.active_strava_token).to eq "xxx"
    end

    context "with expired token" do
      let(:expires_at) { Time.current - 1.hour }
      let(:strava_response) do
        {
          access_token: "vvv",
          expires_at: (Time.current + 2.days).to_i,
          expires_in: "wut",
          refresh_token: "qqq",
          token_type: "wut"
        }.as_json
      end
      let(:integration_result) { {json: strava_response, status: status} }
      let(:status) { 200 }
      before { allow(StravaIntegration).to receive(:refresh_access_token).with("zzz").and_return(integration_result) }
      it "updates strava token" do
        expect(user.active_strava_token).to eq "vvv"
        user.reload
        expect(user.strava_auth).to eq({"token" => "vvv", "refresh_token" => "qqq", "expires_at" => strava_response["expires_at"]})
      end
      context "with invalid strava response" do
        let(:strava_response) { {message: "Bad Request", errors: [{resource: "RefreshToken", field: "refresh_token", code: "invalid"}]} }
        let(:status) { 401 }
        it "doesn't update token" do
          expect do
            user.active_strava_token
          end.to raise_error(/Bad Request/)
        end
      end
    end

    context "with no strava_auth" do
      let(:user) { FactoryBot.create(:user) }
      it "raises" do
        expect { user.active_strava_token }.to raise_error(/invalid/i)
      end
    end
  end

  describe "after_commit" do
    let(:user) { FactoryBot.create(:user) }
    let(:start_date) { Time.current.beginning_of_month }
    let(:competition) { FactoryBot.create(:competition, start_date: start_date - 1.year, current: false) }
    let(:competition_current) { FactoryBot.create(:competition, start_date: start_date, current: true) }
    let(:updated_at) { Time.current - 1.day }
    let!(:competition_user) { FactoryBot.create(:competition_user, user:, competition: competition, updated_at:) }
    let!(:competition_user_current) { FactoryBot.create(:competition_user, user:, competition: competition_current, updated_at:) }
    it "touches current_competition_user" do
      expect(CompetitionUser.included_in_current_competition.pluck(:id)).to eq([competition_user_current.id])
      Competition.current(re_memoize: true)
      user.update(display_name: "New name")
      expect(competition_user.reload.updated_at).to be_within(1).of updated_at
      expect(competition_user_current.reload.updated_at).to be_within(1).of Time.current
    end
  end
end

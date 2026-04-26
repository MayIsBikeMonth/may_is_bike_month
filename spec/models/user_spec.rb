require "rails_helper"

RSpec.describe User, type: :model do
  describe "factory" do
    let(:user) { FactoryBot.create(:user) }

    it "is valid" do
      expect(user).to be_valid
      expect(User.friendly_find_id(user.display_name)).to eq user.id
      expect(User.friendly_find_id(user.strava_username)).to eq user.id
      expect(User.friendly_find_id(user.id.to_s)).to eq user.id
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
      it "updates strava token" do
        VCR.use_cassette("strava_integration-refresh_access_token-success", match_requests_on: [:path]) do
          expect(user.active_strava_token).to eq "zzzzxxxxxxx"
          user.reload
          expect(user.strava_auth).to eq({"token" => "zzzzxxxxxxx", "refresh_token" => "xxxzzzz", "expires_at" => 1714533563})
        end
      end
      context "with invalid strava response" do
        it "doesn't update token" do
          VCR.use_cassette("strava_integration-refresh_access_token-error", match_requests_on: [:path]) do
            expect do
              user.active_strava_token
            end.to raise_error(/Bad Request/)
          end
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

  describe "from_omniauth" do
    let(:uid) { 123456 }
    let(:auth) do
      {
        "credentials" => {"token" => "tok", "refresh_token" => "refresh", "expires_at" => (Time.current + 1.hour).to_i},
        "extra" => {"raw_info" => {"username" => "new-rider", "firstname" => "New", "lastname" => "Rider"}}
      }
    end

    it "creates a new user with a password" do
      expect { User.from_omniauth(uid, auth) }.to change(User, :count).by(1)
      user = User.find_by(strava_id: uid)
      expect(user.strava_username).to eq "new-rider"
      expect(user.encrypted_password).to be_present
    end

    context "when the user already exists" do
      let!(:existing) { FactoryBot.create(:user, strava_id: uid) }

      it "updates strava data without rotating encrypted_password" do
        original_encrypted_password = existing.encrypted_password
        expect { User.from_omniauth(uid, auth) }.not_to change(User, :count)
        existing.reload
        expect(existing.encrypted_password).to eq original_encrypted_password
        expect(existing.strava_auth["token"]).to eq "tok"
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
      user.update(display_name: "New name")
      expect(competition_user.reload.updated_at).to be_within(1).of updated_at
      expect(competition_user_current.reload.updated_at).to be_within(1).of Time.current
    end
  end
end

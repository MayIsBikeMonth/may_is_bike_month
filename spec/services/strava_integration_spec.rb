require "rails_helper"

RSpec.describe StravaIntegration, type: :model do
  describe "refresh_access_token" do
    let(:refresh_token) { "valid-refresh-token" }
    let(:result) { described_class.refresh_access_token(refresh_token) }
    it "returns a valid access_token" do
      VCR.use_cassette("strava_integration-refresh_access_token-success", match_requests_on: [:path]) do
        expect(result.keys.sort).to eq(%w[json status])
        expect(result["status"]).to eq 200
        expect(result["json"].keys.sort).to eq(%w[access_token expires_at expires_in refresh_token token_type])
      end
    end

    context "with invalid token" do
      let(:refresh_token) { "invalid" }
      let(:invalid_response) { {message: "Bad Request", errors: [{resource: "RefreshToken", field: "refresh_token", code: "invalid"}]} }

      it "returns a valid access_token" do
        VCR.use_cassette("strava_integration-refresh_access_token-error", match_requests_on: [:path]) do
          expect(result["status"]).to eq 400
          expect(result["json"]).to eq invalid_response.as_json
        end
      end
    end
  end

  describe "get_activities narrowed to activity 18111714404" do
    # Activity 18111714404 starts at 2026-04-14T23:03:36Z. Use before/after
    # query parameters to fetch a window containing exactly that activity,
    # then create a CompetitionActivity from the returned strava_data so we
    # can pin down exactly how the Peloton-→-Strava Central-time ride maps
    # onto our model.
    let(:access_token) { ENV.fetch("STRAVA_RECORD_TOKEN", "xxxx") }
    let(:activity_id) { 18_111_714_404 }
    let(:parameters) do
      {
        after: Time.utc(2026, 4, 14).to_i,
        before: Time.utc(2026, 4, 15).to_i,
        per_page: 10
      }
    end
    let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2026-04-01")) }
    let(:competition_user) { FactoryBot.create(:competition_user, competition:) }

    it "creates a CompetitionActivity from the returned strava_data with the expected attributes" do
      VCR.use_cassette("strava_integration-get_activity-18111714404", match_requests_on: [:path]) do
        result = described_class.get_activities(access_token, parameters:)
        expect(result["status"]).to eq 200

        strava_data = result["json"].find { |a| a["id"] == activity_id }
        activity = CompetitionActivity.find_or_create_if_valid(competition_user:, strava_data:)

        expect(activity).to be_valid
        expect(activity).to have_attributes(
          strava_id: "18111714404",
          display_name: "20 min HIIT Ride with Emma Lovewell",
          timezone: "America/Chicago",
          start_at: Time.parse("2026-04-14T23:03:36Z"),
          distance_meters: 12_027.3,
          moving_seconds: 1200,
          elevation_meters: 0.0,
          activity_dates_strings: ["2026-04-14"],
          included_in_competition: true
        )
      end
    end
  end

  describe "get_activities" do
    let(:access_token) { "xxxx" }
    let(:result) { described_class.get_activities(access_token, parameters: {per_page: 1}) }
    it "is success" do
      VCR.use_cassette("strava_integration-get_activities-success", match_requests_on: [:path]) do
        expect(result.keys).to eq(%w[json status])
        expect(result["json"].length).to eq 1
      end
    end

    context "with authorization error" do
      let(:access_token) { "invalid-token" }
      let(:invalid_response) { {message: "Authorization Error", errors: [{resource: "Athlete", field: "access_token", code: "invalid"}]} }
      it "fails success" do
        VCR.use_cassette("strava_integration-get_activities-error", match_requests_on: [:path]) do
          expect(result["status"]).to eq 401
          expect(result["json"]).to eq invalid_response.as_json
        end
      end
    end
  end
end

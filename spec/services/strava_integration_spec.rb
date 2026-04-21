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
    # query parameters to fetch a window containing exactly that activity so
    # we can inspect its strava_data payload.
    let(:access_token) { ENV.fetch("STRAVA_RECORD_TOKEN", "xxxx") }
    let(:activity_id) { 18_111_714_404 }
    let(:parameters) do
      {
        after: Time.utc(2026, 4, 14).to_i,
        before: Time.utc(2026, 4, 15).to_i,
        per_page: 10
      }
    end
    let(:result) { described_class.get_activities(access_token, parameters:) }

    it "returns activity 18111714404 with its strava_data payload" do
      VCR.use_cassette("strava_integration-get_activity-18111714404", match_requests_on: [:path]) do
        expect(result["status"]).to eq 200
        activity = result["json"].find { |a| a["id"] == activity_id }
        expect(activity).not_to be_nil
        # Surface a handful of fields so `rspec --format documentation` shows
        # the shape of the payload (useful for debugging timezone quirks).
        %w[name type trainer timezone start_date_local utc_offset].each do |key|
          puts "  strava_data[#{key.inspect}] = #{activity[key].inspect}"
        end
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

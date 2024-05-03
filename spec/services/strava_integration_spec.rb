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

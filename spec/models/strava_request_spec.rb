require "rails_helper"

RSpec.describe StravaRequest, type: :model do
  describe "record_request_for_user_activities" do
    let(:user) { FactoryBot.create(:user_with_strava_token) }
    it "creates a strava_request" do
      VCR.use_cassette("strava_integration-get_activities-success", match_requests_on: [:path]) do
        expect do
          StravaRequest.send(:record_request_for_user_activities, user: user, parameters: {per_page: "2"})
        end.to change(StravaRequest, :count).by 1

        strava_request = StravaRequest.last
        expect(strava_request.user_id).to eq user.id
        expect(strava_request.kind).to eq "get_activities"
        expect(strava_request.success_response?).to be_truthy
        expect(strava_request.error_response).to be_nil
        expect(strava_request.parameters).to eq({"per_page" => "2"})
      end
    end

    context "error response" do
      it "creates a strava_request" do
        VCR.use_cassette("strava_integration-get_activities-error", match_requests_on: [:path]) do
          expect do
            StravaRequest.send(:record_request_for_user_activities, user: user, parameters: {per_page: "2"})
          end.to change(StravaRequest, :count).by 1

          strava_request = StravaRequest.last
          expect(strava_request.user_id).to eq user.id
          expect(strava_request.kind).to eq "get_activities"
          expect(strava_request.success_response?).to be_falsey
          expect(strava_request.error_response).to be_present
          expect(strava_request.parameters).to eq({"per_page" => "2"})
        end
      end
    end
  end

  describe "parameters_for_competition_activities" do
    let(:competition) { FactoryBot.create(:competition, start_date: Time.parse("2024-05-01").utc.beginning_of_day) }
    let(:target) do
      {
        "before" => 1717397999,
        "after" => 1714374000,
        "per_page" => "100"
      }
    end

    it "responds with expected parameters" do
      expect(StravaRequest.send(:parameters_for_competition_activities, competition)).to eq target
    end
  end
end

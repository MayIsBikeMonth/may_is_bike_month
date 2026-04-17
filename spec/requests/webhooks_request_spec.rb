# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/webhooks", type: :request do
  describe "get strava (subscription verification)" do
    let(:verify_token) { "test_verify_token" }
    around do |example|
      original = ENV["STRAVA_WEBHOOK_VERIFY_TOKEN"]
      ENV["STRAVA_WEBHOOK_VERIFY_TOKEN"] = verify_token
      example.run
    ensure
      ENV["STRAVA_WEBHOOK_VERIFY_TOKEN"] = original
    end

    context "with valid verify_token" do
      it "echoes the challenge" do
        get "/webhooks/strava", params: {
          "hub.mode" => "subscribe",
          "hub.verify_token" => verify_token,
          "hub.challenge" => "test_challenge_abc"
        }
        expect(response.code).to eq "200"
        expect(json_result).to eq({"hub.challenge" => "test_challenge_abc"})
      end
    end

    context "with invalid verify_token" do
      it "returns 403" do
        get "/webhooks/strava", params: {
          "hub.mode" => "subscribe",
          "hub.verify_token" => "wrong_token",
          "hub.challenge" => "test_challenge_abc"
        }
        expect(response.code).to eq "403"
      end
    end

    context "with blank verify_token and blank configured token" do
      let(:verify_token) { nil }

      it "returns 403" do
        get "/webhooks/strava", params: {"hub.mode" => "subscribe"}
        expect(response.code).to eq "403"
      end
    end
  end

  describe "post strava (event receiver)" do
    let(:user) { FactoryBot.create(:user) }
    let(:event_params) do
      {
        object_type: "activity",
        aspect_type: "create",
        object_id: 12345678987654321,
        owner_id: user.strava_id.to_i,
        subscription_id: 999
      }
    end
    before { Sidekiq::Job.clear_all }

    context "with known athlete" do
      it "creates StravaRequest and enqueues processing job" do
        expect {
          post "/webhooks/strava", params: event_params, as: :json
        }.to change(StravaRequest, :count).by(1)
        expect(response.code).to eq "200"

        strava_request = StravaRequest.last
        expect(strava_request.incoming_webhook?).to be true
        expect(strava_request.user_id).to eq user.id
        expect(strava_request.parameters["object_type"]).to eq "activity"
        expect(strava_request.parameters["aspect_type"]).to eq "create"
        expect(strava_request.parameters["object_id"]).to eq 12345678987654321
        expect(strava_request.parameters["owner_id"]).to eq user.strava_id.to_i
        expect(ProcessStravaWebhookJob.jobs.count).to eq 1
        expect(ProcessStravaWebhookJob.jobs.last["args"]).to eq [strava_request.id]
      end
    end

    context "with unknown owner_id" do
      it "returns 200 and does not persist" do
        expect {
          post "/webhooks/strava", params: event_params.merge(owner_id: 99999999), as: :json
        }.not_to change(StravaRequest, :count)
        expect(response.code).to eq "200"
        expect(ProcessStravaWebhookJob.jobs.count).to eq 0
      end
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/landing", type: :request do
  describe "get root" do
    it "renders" do
      get "/"
      expect(response.code).to eq "200"
    end
  end

  describe "get update_strava" do
    let!(:competition_user) { FactoryBot.create(:competition_user) }
    before { Sidekiq::Worker.clear_all }

    it "enqueues jobs and returns json" do
      expect(UpdateCompetitionUserJob.jobs.count).to eq 0
      get "/update_strava"
      expect(response.code).to eq "200"
      expect(json_result).to eq({message: "success"}.as_json)
      expect(UpdateCompetitionUserJob.jobs.count).to eq 1
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/competitions", type: :request do
  describe "get root" do
    let!(:competition) { FactoryBot.create(:competition) }
    it "renders" do
      get "/competitions/#{competition.slug}"
      expect(response.code).to eq "200"
      expect(response).to render_template("show")
    end

    context "legacy competition" do
      let(:competition) do
        FactoryBot.create(:competition, kind: :legacy,
          start_date: Date.parse("2023-05-01"), end_date: Date.parse("2023-05-31"))
      end
      let(:user) { FactoryBot.create(:user, display_name: "Rider One") }
      let!(:competition_user) do
        FactoryBot.create(:competition_user, competition:, user:,
          score_data: {dates: [], distance: 100_000, elevation: 1_000,
                       periods: competition.periods.map { |p| p.merge(distance: 20_000, elevation: 200) }})
      end
      it "renders the legacy leaderboard without punchcard" do
        get "/competitions/#{competition.slug}"
        expect(response.code).to eq "200"
        expect(response.body).to include("Rider One")
        expect(response.body).to include("Winner is the person who rides the most total miles")
        expect(response.body).to include("Show all activities")
        expect(response.body).to include("Hide all activities")
        expect(response.body).to include('data-controller="legacy-activities"')
        expect(response.body).not_to include("Everyday")
      end
    end
  end
end

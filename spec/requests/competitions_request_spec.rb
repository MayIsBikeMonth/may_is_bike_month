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

    context "with a legacy competition" do
      let(:competition) { FactoryBot.create(:competition, kind: :legacy, start_date: Date.new(2023, 5, 1)) }
      let(:user) { FactoryBot.create(:user, display_name: "Noah", strava_id: nil) }
      let!(:competition_user) do
        FactoryBot.create(:competition_user, competition:, user:,
          display_name: "Noah",
          score_data: {dates: [], distance: 2_949_928, elevation: 31_897})
      end
      it "renders without punches and with legacy rules" do
        get "/competitions/#{competition.slug}"
        expect(response.code).to eq "200"
        expect(response.body).to include("Winner rode the most total miles")
        expect(response.body).to include("Pre-Strava")
        expect(response.body).not_to include("Everyday<br>Riders")
        expect(response.body).not_to include("punchcard-week")
        expect(response.body).not_to include("punch-activities-container")
        expect(response.body).to include("Noah")
      end
    end
  end
end

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
        expect(response.body).to include('data-controller="legacy-activities"')
        expect(response.body).not_to include("Show all activities")
        expect(response.body).not_to include("Everyday")
      end
    end
  end

  describe "GET /history" do
    let(:modern_competition) do
      FactoryBot.create(:competition, display_name: "MIBM 2024",
        start_date: Date.parse("2024-05-01"), end_date: Date.parse("2024-05-31"))
    end
    let(:legacy_competition) do
      FactoryBot.create(:competition, kind: :legacy, display_name: "MIBM 2023",
        start_date: Date.parse("2023-05-01"), end_date: Date.parse("2023-05-31"))
    end
    let(:modern_dates) { Competition.dates_strings(modern_competition.start_date, modern_competition.end_date) }

    def create_modern_user(name:, distance:, elevation:, dates:)
      user = FactoryBot.create(:user, display_name: name)
      FactoryBot.create(:competition_user, competition: modern_competition, user:,
        score_data: {dates:, distance:, elevation:,
                     periods: modern_competition.periods.map { |p| p.merge(distance: 0, elevation: 0) }})
    end

    def create_legacy_user(name:, distance:, elevation:)
      user = FactoryBot.create(:user, display_name: name)
      FactoryBot.create(:competition_user, competition: legacy_competition, user:,
        score_data: {dates: [], distance:, elevation:,
                     periods: legacy_competition.periods.map { |p| p.merge(distance: 0, elevation: 0) }})
    end

    before do
      create_modern_user(name: "Alice Modern", distance: 500_000, elevation: 5_000, dates: modern_dates)
      create_modern_user(name: "Bob Modern", distance: 400_000, elevation: 4_000, dates: modern_dates[0..20])
      create_modern_user(name: "Carol Modern", distance: 300_000, elevation: 3_000, dates: modern_dates[0..10])
      create_modern_user(name: "Dave Modern", distance: 50_000, elevation: 500, dates: modern_dates[0..2])
      create_legacy_user(name: "Alice Legacy", distance: 800_000, elevation: 8_000)
      create_legacy_user(name: "Bob Legacy", distance: 300_000, elevation: 3_000)
      create_legacy_user(name: "Carol Legacy", distance: 100_000, elevation: 1_000)
    end

    it "renders history with placings, totals and legacy everyday dash" do
      get "/history"
      expect(response.code).to eq "200"
      expect(response).to render_template("history")

      expect(response.body).to include("MIBM 2024")
      expect(response.body).to include("MIBM 2023")
      expect(response.body).to include("legacy")

      # Modern podium + last (4 users, so last ≠ 3rd)
      expect(response.body).to include("Alice Modern")
      expect(response.body).to include("Bob Modern")
      expect(response.body).to include("Carol Modern")
      expect(response.body).to include("Dave Modern")

      # Legacy has only 3 users, so last should render as em-dash
      expect(response.body).to include("Alice Legacy")
      expect(response.body).to include("Bob Legacy")
      expect(response.body).to include("Carol Legacy")

      # Legacy competitions get em-dash for everyday (no count possible)
      expect(response.body).to include("&mdash;").or include("—")
    end
  end
end

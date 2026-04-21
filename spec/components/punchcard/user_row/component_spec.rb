# frozen_string_literal: true

require "rails_helper"

RSpec.describe Punchcard::UserRow::Component, type: :component do
  let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2025-05-01")) }
  let(:user) { FactoryBot.create(:user, display_name: "Sam Daly", strava_id: "daly_sam") }
  let(:competition_user) do
    cu = FactoryBot.create(:competition_user, user:, competition:)
    cu.update_columns(
      score_data: {dates: ["2025-05-01", "2025-05-02"], distance: 40_000.0, elevation: 600.0},
      score: 2.5
    )
    cu.reload
  end
  let(:period_date_strings) do
    (competition.start_date..competition.end_date).map(&:to_s)
  end
  let(:user_daily) do
    {
      "2025-05-01" => {distance_meters: 32_186.88, elevation_meters: 300}, # 20 mi => l=3
      "2025-05-02" => {distance_meters: 3_218, elevation_meters: 50}, # ~2 mi => below daily req
      "2025-05-04" => {distance_meters: 160_934.4, elevation_meters: 900} # 100 mi => century, l=5
    }
  end
  let(:component) do
    described_class.new(
      competition_user:,
      competition:,
      rank: 1,
      period_date_strings:,
      user_daily:
    )
  end
  let(:rendered) { render_inline(component) }

  it "renders the rank" do
    expect(rendered.text).to include "1"
  end

  it "renders the user display name" do
    expect(rendered.text).to include "Sam Daly"
  end

  it "renders strava link" do
    expect(rendered.css("a").attr("href").value).to eq user.strava_user_url
  end

  it "renders 31 cells" do
    expect(rendered.css(".punchcard-cell").count).to eq 31
  end

  it "sets --start-col on the punchcard grid for small-screen weekday alignment" do
    # May 1, 2025 is a Thursday (wday=4), Mon-indexed column 4
    style = rendered.css(".punchcard-week").attr("style").value
    expect(style).to include "--start-col: 4"
  end

  it "assigns data-l based on distance" do
    cells = rendered.css(".punchcard-cell")
    expect(cells[0].attr("data-l")).to eq "3"
  end

  it "omits data-l for days below the daily requirement" do
    cells = rendered.css(".punchcard-cell")
    expect(cells[1].attr("data-l")).to be_nil
    expect(cells[1].attr("title")).to eq "no rides"
  end

  it "marks the century day" do
    cells = rendered.css(".punchcard-cell")
    expect(cells[3].attr("data-century")).not_to be_nil
    expect(cells[3].attr("data-l")).to eq "5"
  end

  it "shows days_count / days_so_far (competition ended, full 31)" do
    expect(rendered.text).to include "/31"
  end

  context "with a competition covering today (2026-04-16)" do
    let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2026-04-01")) }
    let(:period_date_strings) { (competition.start_date..competition.end_date).map(&:to_s) }
    let(:user_daily) { {} }
    around { |ex| travel_to(Date.parse("2026-04-16")) { ex.run } }

    it "renders cells only for past days; today and future stay as plain spans until activity lands" do
      expect(rendered.css("div.h-7 > *").count).to eq 30
      # past (15) = 15 cells; today + future (15) are plain spans
      expect(rendered.css("div.h-7 .punchcard-cell").count).to eq 15
    end

    it "uses days_so_far (days through current_date, inclusive) as the denominator" do
      expect(rendered.text).to include "/16"
    end

    context "when the user has activity today" do
      let(:user_daily) { {"2026-04-16" => {distance_meters: 16_093, elevation_meters: 100}} }

      it "renders today as a clickable punch button" do
        today_cell = rendered.css("div.h-7 > *")[15]
        expect(today_cell.name).to eq "button"
        expect(today_cell["data-date"]).to eq "2026-04-16"
      end

      it "includes today's activity in the punch-activities-container" do
        competition_user.competition_activities << FactoryBot.create(:competition_activity,
          competition_user:, distance_meters: 16_093, start_at: Time.parse("2026-04-16T15:00:00Z"))
        expect(rendered.css(%([data-punch-activities-for="#{user.slug}-2026-04-16"])).count).to eq 1
      end
    end

    context "when current_date has rolled into tomorrow for this user (eastward timezone)" do
      # Simulates the timezone case: it's still 4/16 for the viewer but the
      # competition_user's timezone puts them at 4/17 with no activity yet.
      # We must not render an "x" for 4/17.
      before { allow(competition_user).to receive(:current_date).and_return(Date.parse("2026-04-17")) }

      it "keeps 4/17 as an upcoming plain span (no x) when there's no activity" do
        tomorrow_cell = rendered.css("div.h-7 > *")[16]
        expect(tomorrow_cell.name).to eq "span"
        expect(tomorrow_cell["class"]).to be_nil
      end
    end
  end

  # Exercises the real timezone resolution: current_date comes from
  # Time.current evaluated in the user's timezone (derived from their latest
  # activity). Nothing past that cutoff may render an "x".
  describe "upcoming-day cutoff honors the user's current timezone" do
    let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2026-04-01")) }
    let(:period_date_strings) { (competition.start_date..competition.end_date).map(&:to_s) }
    let(:user_daily) { {} }

    # Viewer wall-clock: 2026-04-16 23:00 UTC-7 (still the 16th).
    # Same instant in America/Chicago: 2026-04-17 01:00 — so for a Chicago
    # rider current_date = 4/17 even though the viewer thinks it's 4/16.
    around { |ex| travel_to(Time.parse("2026-04-17T06:00:00Z")) { ex.run } }

    before do
      FactoryBot.create(:competition_activity,
        competition_user:,
        timezone: "America/Chicago",
        start_at: Time.parse("2026-04-10T15:00:00Z"))
    end

    it "renders no x on or after the user's current_date" do
      expect(competition_user.current_date.to_s).to eq "2026-04-17"

      period_date_strings.each_with_index do |date_string, idx|
        el = rendered.css("div.h-7 > *")[idx]
        past = date_string < competition_user.current_date.to_s
        if past
          # past days with no activity render the "x" cell
          expect(el["class"]).to include("punchcard-cell"),
            "expected #{date_string} to be a past 'x' cell"
        else
          # today (4/17 here) and beyond stay hidden — no x yet
          expect(el["class"]).to be_nil,
            "expected #{date_string} to be an upcoming plain span (no x), got class=#{el["class"].inspect}"
        end
      end
    end
  end
end

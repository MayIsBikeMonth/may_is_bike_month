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

  it "renders rank zero-padded" do
    expect(rendered.text).to include "01"
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

  it "shows total days / period days" do
    expect(rendered.text).to include "/31"
  end

  context "with dates at or after the competition_user's current_date" do
    let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2026-04-01")) }
    let(:period_date_strings) { (competition.start_date..competition.end_date).map(&:to_s) }
    let(:user_daily) { {} }

    before do
      allow(competition_user).to receive(:current_date).and_return(Date.parse("2026-04-16"))
    end

    it "renders empty spans for today and future, punchcard-cells only for past days" do
      cells = rendered.css(".grid-cols-\\[repeat\\(31\\,1fr\\)\\] > span")
      expect(cells.count).to eq 30
      punch_cells = rendered.css(".punchcard-cell")
      expect(punch_cells.count).to eq 15
      empty_spans = cells.reject { |c| c["class"]&.include?("punchcard-cell") }
      expect(empty_spans.count).to eq 15
    end
  end
end

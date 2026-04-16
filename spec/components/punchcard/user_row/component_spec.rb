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
      "2025-05-01" => {distance_meters: 32_186.88, elevation_meters: 300}, # 20 miles => l=4
      "2025-05-02" => {distance_meters: 1_609.344, elevation_meters: 50}, # 1 mi => no rides (below 2mi)
      "2025-05-04" => {distance_meters: 160_934.4, elevation_meters: 900} # 100 mi => century, l=5
    }
  end
  let(:component) do
    described_class.new(
      competition_user:,
      rank: 1,
      period_date_strings:,
      user_daily:
    )
  end
  let(:rendered) { render_inline(component) }

  it "renders rank zero-padded" do
    expect(rendered.css(".punchcard-rank").text).to eq "01"
  end

  it "renders the user display name" do
    expect(rendered.css(".punchcard-name").text).to eq "Sam Daly"
  end

  it "renders strava link" do
    expect(rendered.css(".punchcard-strava").attr("href").value).to eq user.strava_user_url
  end

  it "renders 31 cells" do
    expect(rendered.css(".punchcard-cell").count).to eq 31
  end

  it "assigns data-l based on distance" do
    cells = rendered.css(".punchcard-cell")
    expect(cells[0].attr("data-l")).to eq "4"
  end

  it "omits data-l for days below the 2 mile threshold" do
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
    totals_text = rendered.css(".punchcard-totals").text
    expect(totals_text).to include "2"
    expect(totals_text).to include "/31"
  end
end

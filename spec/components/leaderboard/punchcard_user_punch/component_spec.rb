# frozen_string_literal: true

require "rails_helper"

RSpec.describe Leaderboard::PunchcardUserPunch::Component, type: :component do
  let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2025-05-01")) }
  let(:component) do
    described_class.new(
      date_string: "2025-05-01",
      distance_meters:,
      competition:
    )
  end
  let(:rendered) { render_inline(component) }

  context "when distance is below the daily requirement" do
    let(:distance_meters) { 1_000 }

    it "renders a cell with no data-l and 'no rides' title" do
      cell = rendered.css(".punchcard-cell").first
      expect(cell.attr("data-l")).to be_nil
      expect(cell.attr("data-century")).to be_nil
      expect(cell.attr("title")).to eq "no rides"
    end
  end

  context "when distance qualifies for a level" do
    let(:distance_meters) { 32_186.88 } # 20 mi => level 3

    it "renders data-l and a titled cell" do
      cell = rendered.css(".punchcard-cell").first
      expect(cell.attr("data-l")).to eq "3"
      expect(cell.attr("data-century")).to be_nil
      expect(cell.attr("title")).to eq "2025-05-01: 20.0 mi"
    end
  end

  context "when distance is a century" do
    let(:distance_meters) { 160_934.4 } # 100 mi => century, level 5

    it "marks the cell as century with the top level" do
      cell = rendered.css(".punchcard-cell").first
      expect(cell.attr("data-l")).to eq "5"
      expect(cell.attr("data-century")).not_to be_nil
    end
  end

  context "when upcoming" do
    let(:component) do
      described_class.new(
        date_string: "2025-05-15",
        distance_meters: 0,
        competition:,
        upcoming: true
      )
    end

    it "renders an empty span with no punchcard-cell class" do
      expect(rendered.css(".punchcard-cell")).to be_empty
      expect(rendered.css("span").count).to eq 1
      expect(rendered.css("span").first.text).to eq ""
      expect(rendered.css("span").first.attributes).to be_empty
    end
  end
end

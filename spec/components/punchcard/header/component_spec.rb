# frozen_string_literal: true

require "rails_helper"

RSpec.describe Punchcard::Header::Component, type: :component do
  let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2025-05-01")) }
  let(:options) do
    {
      competition:,
      rider_count: 19,
      distance_meters: 8_215 * 1609.344, # 8,215 mi
      elevation_meters: 496_100 / 3.28084, # 496,100 ft
      everyday_rider_count: 6
    }
  end
  let(:rendered) { render_inline(described_class.new(**options)) }

  it "renders the display_name with the year highlighted" do
    h1 = rendered.css("h1")
    expect(h1.text.squish).to eq "MIBM 2025"
    expect(h1.css("b.text-purple-500").text).to eq "2025"
  end

  context "with a custom display_name containing the year" do
    let(:competition) do
      FactoryBot.create(:competition, start_date: Date.parse("2026-04-01"), display_name: "MIBM April 2026")
    end

    it "highlights the year within the display_name" do
      h1 = rendered.css("h1")
      expect(h1.text.squish).to eq "MIBM April 2026"
      expect(h1.css("b.text-purple-500").text).to eq "2026"
    end
  end

  it "renders the rider count" do
    expect(rendered.to_html).to include ">19</div>"
  end

  it "formats feet over 1k with a k" do
    imperial_text = rendered.css(".unit-imperial").map(&:text).join(" ")
    expect(imperial_text).to match(/496\s*k/)
  end

  context "with feet under 1000" do
    let(:options) { super().merge(elevation_meters: 500 / 3.28084) }

    it "renders raw feet without k suffix" do
      imperial_text = rendered.css(".unit-imperial").map(&:text).join(" ")
      expect(imperial_text).to include "500"
      expect(imperial_text).not_to match(/500\s*k/)
    end
  end

  it "renders imperial and metric toggle spans for miles and feet" do
    expect(rendered.css(".unit-imperial").count).to eq 4
    expect(rendered.css(".unit-metric.hidden").count).to eq 4
  end

  context "when the competition is over" do
    # 2025 competition; today is 2026-04-16 per CLAUDE.md
    it "omits the Days Left metric" do
      expect(rendered.text).not_to include "Days"
    end
  end

  context "when the competition is current (April 2026, today 2026-04-16)" do
    let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2026-04-01")) }
    around { |ex| travel_to(Date.parse("2026-04-16")) { ex.run } }

    it "shows Days Left to the left of Riders" do
      labels = rendered.css("div.text-\\[10px\\]").map(&:text).map(&:squish)
      expect(labels.first).to eq "DaysLeft"
      expect(labels[1]).to eq "Riders"
      numbers = rendered.css("div.text-\\[22px\\]").map(&:text).map(&:strip)
      expect(numbers.first).to eq "15" # 2026-04-16..2026-04-30 inclusive
    end
  end
end

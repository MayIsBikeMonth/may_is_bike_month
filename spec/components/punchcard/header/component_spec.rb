# frozen_string_literal: true

require "rails_helper"

RSpec.describe Punchcard::Header::Component, type: :component do
  let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2025-05-01")) }
  let(:options) do
    {
      competition:,
      rider_count: 19,
      total_miles: 8_215,
      total_feet: 496_100,
      everyday_rider_count: 6
    }
  end
  let(:rendered) { render_inline(described_class.new(**options)) }

  it "renders the year from the competition" do
    expect(rendered.css("h1").text).to include "2025"
  end

  it "renders the rider count" do
    expect(rendered.to_html).to include ">19</div>"
  end

  it "formats feet over 1k with a k" do
    imperial_text = rendered.css(".unit-imperial").map(&:text).join(" ")
    expect(imperial_text).to match(/496\s*k/)
  end

  context "with feet under 1000" do
    let(:options) { super().merge(total_feet: 500) }

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
end

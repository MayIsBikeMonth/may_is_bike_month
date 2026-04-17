# frozen_string_literal: true

require "rails_helper"

RSpec.describe Punchcard::Ridge::Component, type: :component do
  let(:daily_totals) do
    [
      {distance_meters: 100_000, elevation_meters: 500},
      {distance_meters: 50_000, elevation_meters: 200},
      {distance_meters: 0, elevation_meters: 0}
    ]
  end
  let(:rendered) { render_inline(described_class.new(daily_totals:)) }

  it "scales heights proportionally to the max distance" do
    bars = rendered.css("i")
    expect(bars.count).to eq 3
    expect(bars[0].attr("style")).to include "height:100.0%"
    expect(bars[1].attr("style")).to include "height:50.0%"
    expect(bars[2].attr("style")).to include "height:0.0%"
  end

  it "renders a title with miles and feet" do
    title = rendered.css("i").first.attr("title")
    expect(title).to include "mi"
    expect(title).to include "ft"
  end

  context "when all totals are zero" do
    let(:daily_totals) { [{distance_meters: 0, elevation_meters: 0}] }

    it "does not divide by zero" do
      expect { rendered }.not_to raise_error
      expect(rendered.css("i").first.attr("style")).to include "height:0.0%"
    end
  end
end

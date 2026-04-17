# frozen_string_literal: true

require "rails_helper"

RSpec.describe Punchcard::Ridge::Component, type: :component do
  let(:daily_totals) do
    [
      {date_string: "2025-05-01", distance_meters: 100_000, elevation_meters: 500},
      {date_string: "2025-05-02", distance_meters: 50_000, elevation_meters: 200},
      {date_string: "2025-05-03", distance_meters: 0, elevation_meters: 0}
    ]
  end
  let(:rendered) { render_inline(described_class.new(daily_totals:)) }

  it "scales bar heights in pixels up to the max" do
    bars = rendered.css("button span[style]")
    expect(bars.count).to eq 3
    expect(bars[0].attr("style")).to include "height:56.0px"
    expect(bars[1].attr("style")).to include "height:28.0px"
    expect(bars[2].attr("style")).to include "height:0.0px"
  end

  it "renders each button with day number and a title containing the day of week, miles and feet" do
    buttons = rendered.css("button")
    expect(buttons.count).to eq 3
    expect(buttons[0].text).to include "1"
    title = buttons[0].attr("title")
    expect(title).to include "Thursday"
    expect(title).to include "mi"
    expect(title).to include "ft"
  end

  context "when all totals are zero" do
    let(:daily_totals) { [{date_string: "2025-05-01", distance_meters: 0, elevation_meters: 0}] }

    it "does not divide by zero" do
      expect { rendered }.not_to raise_error
      expect(rendered.css("button span[style]").first.attr("style")).to include "height:0.0px"
    end
  end

  context "with past, today, and future days" do
    let(:daily_totals) do
      [
        {date_string: "2026-05-01", distance_meters: 20_000, elevation_meters: 100},
        {date_string: "2026-05-02", distance_meters: 30_000, elevation_meters: 200},
        {date_string: "2026-05-03", distance_meters: 0, elevation_meters: 0}
      ]
    end

    around { |ex| travel_to(Date.parse("2026-05-02")) { ex.run } }

    it "renders past and today as buttons, future as inert spans" do
      outer_spans = rendered.css("div > span.flex.flex-col")
      expect(rendered.css("button").count).to eq 2
      expect(outer_spans.count).to eq 1
      expect(outer_spans.first.attr("data-action")).to be_nil
      expect(outer_spans.first.attr("title")).to eq "Sunday"
    end
  end
end

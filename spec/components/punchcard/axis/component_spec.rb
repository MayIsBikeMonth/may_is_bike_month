# frozen_string_literal: true

require "rails_helper"

RSpec.describe Punchcard::Axis::Component, type: :component do
  let(:period_dates) { (Date.parse("2025-05-01")..Date.parse("2025-05-31")).to_a }
  let(:rendered) { render_inline(described_class.new(period_dates:)) }

  it "renders all 31 days" do
    spans = rendered.css(".punchcard-axis-days span")
    expect(spans.count).to eq 31
    expect(spans.first.text).to eq "1"
    expect(spans.last.text).to eq "31"
  end

  it "marks weekend days" do
    spans = rendered.css(".punchcard-axis-days span")
    # May 3 2025 is a Saturday (index 2)
    expect(spans[2].attr("class")).to include "we"
    # May 4 2025 is a Sunday
    expect(spans[3].attr("class")).to include "we"
    # May 5 2025 is a Monday
    expect(spans[4].attr("class") || "").not_to include "we"
  end
end

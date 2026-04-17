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
end

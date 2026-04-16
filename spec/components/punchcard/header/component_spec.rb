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
    expect(rendered.css(".punchcard-title").text).to include "2025"
  end

  it "renders the rider count" do
    expect(rendered.to_html).to include ">19</div>"
  end

  it "formats feet over 1k with a k" do
    meta_text = rendered.css(".punchcard-meta").text
    expect(meta_text).to include "496"
    expect(meta_text).to include "k"
  end

  context "with feet under 1000" do
    let(:options) { super().merge(total_feet: 500) }

    it "renders raw feet without k suffix" do
      feet_node = rendered.css(".punchcard-num")[2]
      expect(feet_node.text).not_to include "k"
      expect(feet_node.text.strip).to eq "500"
    end
  end
end

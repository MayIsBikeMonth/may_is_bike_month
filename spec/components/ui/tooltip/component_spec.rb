# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Tooltip::Component, type: :component do
  let(:component) do
    render_inline(described_class.new(text: "5–9 mi")) { "trigger".html_safe }
  end

  it "renders the tooltip text and trigger" do
    expect(component.css("[role='tooltip']").text.strip).to eq "5–9 mi"
    expect(component.text).to include "trigger"
  end

  it "wires aria-describedby to the tooltip id" do
    tooltip_id = component.css("[role='tooltip']").attr("id").value
    expect(tooltip_id).to be_present
    expect(component.css("[aria-describedby='#{tooltip_id}']")).to be_present
  end

  it "makes the trigger focusable" do
    expect(component.css("[aria-describedby]").attr("tabindex").value).to eq "0"
  end

  context "with multiple instances" do
    let(:components) do
      [
        render_inline(described_class.new(text: "one")) { "a".html_safe },
        render_inline(described_class.new(text: "two")) { "b".html_safe }
      ]
    end

    it "generates unique tooltip ids" do
      ids = components.map { |c| c.css("[role='tooltip']").attr("id").value }
      expect(ids.uniq.size).to eq 2
    end
  end
end

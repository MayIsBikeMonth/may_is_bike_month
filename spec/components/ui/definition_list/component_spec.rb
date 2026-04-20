# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::DefinitionList::Component, type: :component do
  let(:component) do
    render_inline(described_class.new) do |list|
      list.with_entry(label: "Email address") { "margotfoster@example.com" }
      list.with_entry(label: "Salary expectation") { "$120,000" }
    end
  end

  it "renders a dl with each entry as a dt/dd pair" do
    expect(component.css("dl").count).to eq 1
    labels = component.css("dt").map { |n| n.text.strip }
    values = component.css("dd").map { |n| n.text.strip }
    expect(labels).to eq ["Email address", "Salary expectation"]
    expect(values).to eq ["margotfoster@example.com", "$120,000"]
  end

  context "with no entries" do
    let(:component) { render_inline(described_class.new) }

    it "renders an empty dl" do
      expect(component.css("dl")).to be_present
      expect(component.css("dt")).to be_empty
    end
  end
end

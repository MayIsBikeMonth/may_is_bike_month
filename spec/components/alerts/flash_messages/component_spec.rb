# frozen_string_literal: true

require "rails_helper"

RSpec.describe Alerts::FlashMessages::Component, type: :component do
  let(:flash) { {} }
  let(:component) { render_inline(described_class.new(flash:)) }

  it "renders empty when no flash messages" do
    expect(component).to be_present
    expect(component).to_not have_css('[role="alert"]')
  end

  context "notice" do
    let(:flash) { {notice: "Saved successfully"} }

    it "renders a notice alert" do
      expect(component).to have_content("Saved successfully")
      expect(component).to have_css('[role="alert"].text-blue-800')
      expect(component).to have_selector("button")
    end
  end

  context "error" do
    let(:flash) { {error: "Something went wrong"} }

    it "renders an error alert" do
      expect(component).to have_content("Something went wrong")
      expect(component).to have_css('[role="alert"].text-red-800')
    end
  end

  context "alert type maps to error" do
    let(:flash) { {alert: "Access denied"} }

    it "renders as error kind" do
      expect(component).to have_content("Access denied")
      expect(component).to have_css('[role="alert"].text-red-800')
    end
  end

  context "multiple messages" do
    let(:flash) { {notice: "Saved", error: "But check this"} }

    it "renders both alerts" do
      expect(component).to have_css('[role="alert"]', count: 2)
      expect(component).to have_content("Saved")
      expect(component).to have_content("But check this")
    end
  end

  context "non-string values are skipped" do
    let(:flash) { {notice: true} }

    it "does not render non-string messages" do
      expect(component).to_not have_css('[role="alert"]')
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Card::Component, type: :component do
  let(:options) { {} }

  let(:component) { render_inline(described_class.new(**options)) }

  it "renders" do
    expect(component).to be_present
  end

  it "pads its content" do
    render_inline(described_class.new) { "in the card" }

    expect(page).to have_css("div[class~='p-4'][class~='rounded-sm'][class~='border']")
    expect(page).to have_content("in the card")
  end

  context "full_bleed" do
    # What it drops, and the width it drops them at, are .twfullbleed's under a container
    # query on the row - all the card owes is the class
    it "marks the card for the row to bleed, without unsetting anything itself" do
      render_inline(described_class.new(full_bleed: true)) { "in the card" }

      expect(page).to have_css("div[class~='twfullbleed'][class~='border'][class~='p-4']")
    end

    it "leaves the class off otherwise" do
      render_inline(described_class.new) { "in the card" }

      expect(page).to have_no_css("div[class~='twfullbleed']")
    end
  end

  context "divided" do
    it "divides its rows instead of padding" do
      render_inline(described_class.new(divided: true)) { "<p>row one</p><p>row two</p>".html_safe }

      expect(page).to have_css("div[class~='divide-y'][class~='rounded-xl'][class~='border']")
      expect(page).to have_no_css("div[class~='p-4']")
      expect(page).to have_content("row one")
      expect(page).to have_content("row two")
    end
  end

  context "shadow" do
    it "adds a small shadow to the gray border, alongside additional_classes" do
      render_inline(described_class.new(shadow: :small, additional_classes: "mt-8"))

      expect(page).to have_css("div[class~='shadow-sm'][class~='border-gray-200'][class~='mt-8']")
    end

    it "swaps the gray border for the sticker's with a black shadow" do
      render_inline(described_class.new(shadow: :black)) { "in the card" }

      expect(page).to have_css("div[class~='border-3'][class~='shadow-[4px_4px_0_#111]'][class~='p-4']")
      expect(page).to have_no_css("div[class~='border-gray-200']")
    end

    it "rounds the large and black cards more" do
      %i[large black].each do |shadow|
        render_inline(described_class.new(shadow:)) { "in the card" }

        expect(page).to have_css("div[class~='rounded-lg']")
        expect(page).to have_no_css("div[class~='rounded-sm']")
      end
    end

    it "has none by default" do
      render_inline(described_class.new) { "in the card" }

      expect(page).to have_no_css("div[class*='shadow']")
    end

    it "rejects anything else" do
      expect { described_class.new(shadow: true) }.to raise_error(ArgumentError, /unknown shadow true/)
    end
  end
end

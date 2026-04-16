# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Landing page", :js, type: :system do
  it "visits root and is accessible" do
    visit root_path

    expect(page).to have_text("May is Bike Month")
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)
  end

  context "when changing theme from settings" do
    it "toggles dark mode" do
      visit root_path

      expect(page).to have_no_css("html.dark")

      find("button[data-open-modal='user-settings-modal']").click
      expect(page).to have_css("dialog[open]")

      find("button[data-theme='theme_dark']").click

      expect(page).to have_css("html.dark")

      find("button[data-theme='theme_light']").click

      expect(page).to have_no_css("html.dark")
    end
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Badge::Component, :js, type: :system do
  it "wraps a tooltip when title differs and renders plain badges otherwise" do
    visit "/lookbook/preview/ui/badge/colors"

    # Plain badge (no custom title) renders without a tooltip wrapper.
    expect(page).to have_css("span.cursor-default")
    expect(page).to have_text "Donor"

    # Badge with a distinct title is wrapped in a hidden tooltip that
    # reveals on hover.
    tooltip = find("[role='tooltip']", visible: :all)
    expect(tooltip.text(:all)).to eq "Notice"
    expect(tooltip).not_to be_visible
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)

    trigger = find("[aria-describedby='#{tooltip[:id]}']")
    expect(trigger).to have_text "N"
    expect(trigger.find("span.cursor-help")).to be_present

    trigger.hover
    expect(tooltip).to be_visible
  end
end

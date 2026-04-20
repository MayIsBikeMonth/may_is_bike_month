# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Badge::Component, :js, type: :system do
  it "renders the title via UI::Tooltip when title differs from text" do
    visit "/lookbook/preview/ui/badge/notice_sm_with_title"

    expect(page).to have_text "N"

    tooltip = find("[role='tooltip']", visible: :all)
    expect(tooltip.text(:all)).to eq "Notice"
    expect(tooltip).not_to be_visible
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)

    find("[aria-describedby='#{tooltip[:id]}']").hover

    expect(tooltip).to be_visible
  end

  it "does not render a tooltip when text suffices as the title" do
    visit "/lookbook/preview/ui/badge/notice_sm"

    expect(page).to have_text "Notice"
    expect(page).to have_no_css("[role='tooltip']", visible: :all)
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Tooltip::Component, :js, type: :system do
  let(:preview_url) { "/lookbook/preview/ui/tooltip/variants" }

  it "is accessible and reveals on hover, hides on mouseleave" do
    visit preview_url

    tooltip = first("[role='tooltip']", visible: :all)
    expect(tooltip.text(:all)).to eq "5–9 mi"
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)
    expect(tooltip).not_to be_visible

    find("[aria-describedby='#{tooltip[:id]}']").hover

    expect(tooltip).to be_visible
    expect(tooltip_position(tooltip[:id])).to include("top" => be_present, "left" => be_present)

    find("body").hover

    expect(tooltip).not_to be_visible
  end

  it "stays open when shown via focus until clicking elsewhere" do
    visit preview_url

    tooltip = first("[role='tooltip']", visible: :all)
    trigger = find("[aria-describedby='#{tooltip[:id]}']")

    page.execute_script("arguments[0].focus()", trigger)
    expect(tooltip).to be_visible

    find("body").click
    expect(tooltip).not_to be_visible
  end

  it "is accessible in dark mode" do
    visit "#{preview_url}?lookbook[display][theme]=dark"

    expect(page).to have_css("[role='tooltip']", visible: :all)
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)
  end

  def tooltip_position(id)
    page.evaluate_script(<<~JS)
      (() => {
        const style = document.getElementById(#{id.to_json}).style
        return { top: style.top, left: style.left }
      })()
    JS
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Tooltip::Component, :js, type: :system do
  let(:preview_url) { "/lookbook/preview/ui/tooltip/variants" }

  it "shows on hover/focus, latches on click, layers in front, and is accessible in light & dark" do
    visit preview_url

    tooltips = all("[role='tooltip']", visible: :all)
    expect(tooltips.size).to be >= 2

    first_tooltip = tooltips.first
    first_trigger = find("[aria-describedby='#{first_tooltip[:id]}']")

    # ----- Initial state ----------------------------------------------
    expect(first_tooltip.text(:all)).to eq "5–9 mi"
    expect(first_tooltip).not_to be_visible
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)

    # ----- Hover reveals; mouseleave hides ----------------------------
    first_trigger.hover
    expect(first_tooltip).to be_visible
    expect(tooltip_position(first_tooltip[:id])).to include("top" => be_present, "left" => be_present)

    find("body").hover
    expect(first_tooltip).not_to be_visible

    # ----- Hover-only state isn't dismissed by click outside ----------
    first_trigger.hover
    page.execute_script("document.body.click()")
    expect(first_tooltip).to be_visible

    find("body").hover
    expect(first_tooltip).not_to be_visible

    # ----- Focus reveals; click outside dismisses ---------------------
    page.execute_script("arguments[0].focus()", first_trigger)
    expect(first_tooltip).to be_visible

    find("body").click
    expect(first_tooltip).not_to be_visible

    # ----- Focus + hover stays through mouseleave; blur clears it -----
    page.execute_script("arguments[0].focus()", first_trigger)
    first_trigger.hover
    expect(first_tooltip).to be_visible

    find("body").hover
    expect(first_tooltip).to be_visible

    page.execute_script("arguments[0].blur()", first_trigger)
    expect(first_tooltip).not_to be_visible

    # ----- Click latches: stays after mouseleave, dismissed by outside click ----
    first_trigger.hover
    first_trigger.click
    find("body").hover
    expect(first_tooltip).to be_visible

    find("body").click
    expect(first_tooltip).not_to be_visible

    # ----- Focus moving to another trigger hides the first ------------
    page.execute_script("arguments[0].focus()", first_trigger)
    expect(first_tooltip).to be_visible

    page.execute_script("arguments[0].focus()", find("[aria-describedby='#{tooltips.last[:id]}']"))
    expect(first_tooltip).not_to be_visible

    # ----- Layering: clicking each trigger in order raises z-index ----
    # The trailing tooltip from the previous phase is closed by the first
    # iteration's focus shift, then reopens on its own iteration with a
    # freshly bumped z-index, so we can run the loop directly against the
    # carried state.
    tooltips.each { |t| find("[aria-describedby='#{t[:id]}']").click }
    z_indexes = tooltips.map { |t| tooltip_z_index(t[:id]).to_i }
    expect(z_indexes).to eq z_indexes.sort
    expect(z_indexes.last).to be > z_indexes.first

    # ----- Dark mode renders and is accessible ------------------------
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

  def tooltip_z_index(id)
    page.evaluate_script("document.getElementById(#{id.to_json}).style.zIndex")
  end
end

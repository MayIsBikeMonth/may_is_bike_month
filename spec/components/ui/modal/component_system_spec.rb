# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Modal::Component, :js, type: :system do
  it "opens, closes via the close button, and dismisses on escape" do
    visit "/lookbook/preview/ui/modal/default"
    expect(page).to have_no_css("dialog[open]")

    click_button("Open Settings")
    expect(page).to have_css("dialog[open]")
    expect(page).to have_content("Modal body content")
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)

    find('[aria-label="Close"]').click
    expect(page).to have_no_css("dialog[open]")

    click_button("Open Settings")
    expect(page).to have_css("dialog[open]")

    send_keys(:escape)
    expect(page).to have_no_css("dialog[open]")
  end
end

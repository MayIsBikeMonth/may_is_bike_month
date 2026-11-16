# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Landing page", :js, type: :system do
  it "renders the heading, is accessible, and lets the user toggle dark mode" do
    # Pin the OS-level preference to light before visiting so the dark-mode
    # toggle assertions don't depend on the developer's machine.
    page.driver.with_playwright_page { it.emulate_media(colorScheme: "light") }

    visit root_path

    expect(page).to have_css("h1", text: /MIBM/)
    expect_axe_clean
    expect(page).to have_no_css("html.dark")

    open_modal("button[commandfor='user-settings-modal']")

    find("button[data-theme='theme_dark']").click
    expect(page).to have_css("html.dark")

    find("button[data-theme='theme_light']").click
    expect(page).to have_no_css("html.dark")
  end
end

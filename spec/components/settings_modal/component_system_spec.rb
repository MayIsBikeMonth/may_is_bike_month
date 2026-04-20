# frozen_string_literal: true

require "rails_helper"

RSpec.describe SettingsModal::Component, :js, type: :system do
  it "opens and closes" do
    visit "/lookbook/preview/settings_modal/default"

    expect(page).to have_no_css("dialog[open]")

    click_button("Open Settings")

    expect(page).to have_css("dialog[open]")
    expect(page).to have_content("Theme")
    expect(page).to have_content("Units")

    find("button[data-action='click->ui--modal#close']").click

    expect(page).to have_no_css("dialog[open]")
  end
end

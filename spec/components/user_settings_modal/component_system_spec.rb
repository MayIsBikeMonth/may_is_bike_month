# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserSettingsModal::Component, :js, type: :system do
  it "opens and closes" do
    visit "/lookbook/preview/user_settings_modal/default"

    expect(page).to have_no_css("dialog[open]")

    find("span", text: "Open Settings").click

    expect(page).to have_css("dialog[open]")
    expect(page).to have_content("Theme")
    expect(page).to have_content("Units")

    find("button[data-action='click->modal#close']").click

    expect(page).to have_no_css("dialog[open]")
  end
end

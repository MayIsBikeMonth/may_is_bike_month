# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Modal::Component, :js, type: :system do
  it "opens and closes" do
    visit "/lookbook/preview/ui/modal/default"

    expect(page).to have_no_css("dialog[open]")

    click_button("Open Settings")

    expect(page).to have_css("dialog[open]")
    expect(page).to have_content("Modal body content")

    find("button[data-action='click->modal#close']").click

    expect(page).to have_no_css("dialog[open]")
  end
end

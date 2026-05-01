# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserDropdown::Component, :js, type: :system do
  it "renders the signed-out and signed-in states on the lookbook preview" do
    visit "/lookbook/preview/user_dropdown/states"

    expect(page).to have_button("Sign in")
    expect(page).to have_text("Rider")
    expect(page).to have_button(id: "user-menu-button")
  end
end

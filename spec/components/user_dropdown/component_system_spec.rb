# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserDropdown::Component, :js, type: :system do
  it "signed_out renders sign in" do
    visit "/lookbook/preview/user_dropdown/states"

    expect(page).to have_button("Sign in")
  end

  it "signed_in renders user dropdown" do
    visit "/lookbook/preview/user_dropdown/states"

    expect(page).to have_text("Rider")
    expect(page).to have_button(id: "user-menu-button")
  end

  it "admin renders admin links" do
    visit "/lookbook/preview/user_dropdown/states"

    expect(page).to have_text("May Is Bike Month Admin")
    expect(page).to have_link("Exit")
  end
end

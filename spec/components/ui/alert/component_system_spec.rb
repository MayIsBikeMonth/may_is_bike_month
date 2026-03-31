# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Alert::Component, type: :system do
  it "dismissable alert renders close button" do
    visit "/lookbook/preview/ui/alert/dismissable_variants"

    expect(page).to have_content "Dismissable"
    expect(page).to have_css('button[aria-label="Close"]')
  end
end

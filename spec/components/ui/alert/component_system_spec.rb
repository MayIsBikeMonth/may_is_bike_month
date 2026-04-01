# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Alert::Component, type: :system do
  it "is dismissable" do
    visit "/lookbook/preview/ui/alert/dismissable_variants"

    expect(page).to have_content "Dismissable"

    first('button[aria-label="Close"]').click

    expect(page).to have_css('[role="alert"]') # at least one alert remains (the other variant)
  end
end

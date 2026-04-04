# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Landing page", :js, type: :system do
  it "visits root and is accessible" do
    visit root_path

    expect(page).to have_text("May is Bike Month", visible: :all)
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)
  end
end

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Form::Group::Component, :js, type: :system do
  it "renders the label/input and is accessible in light and dark themes" do
    visit "/lookbook/preview/form/group/kinds"
    expect(page).to have_css("label")
    expect(page).to have_css("input")
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)

    visit "/lookbook/preview/form/group/kinds?lookbook[display][theme]=dark"
    expect(page).to have_css("label")
    expect(page).to be_axe_clean.skipping(SKIPPABLE_AXE_RULES)
  end
end

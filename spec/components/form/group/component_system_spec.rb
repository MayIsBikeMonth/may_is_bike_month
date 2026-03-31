# frozen_string_literal: true

require "rails_helper"

RSpec.describe Form::Group::Component, type: :system do
  it "renders label and input" do
    visit "/lookbook/preview/form/group/kinds"

    expect(page).to have_css("label")
    expect(page).to have_css("input")
  end
end

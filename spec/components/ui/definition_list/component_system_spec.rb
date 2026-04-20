# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::DefinitionList::Component, :js, type: :system do
  let(:preview_path) { "/rails/view_components/ui/definition_list/component/default" }

  it "default preview" do
    visit(preview_path)

    expect(page).to have_css("dl dt", text: "Application for")
    expect(page).to have_css("dl dd", text: "Backend Developer")
  end
end

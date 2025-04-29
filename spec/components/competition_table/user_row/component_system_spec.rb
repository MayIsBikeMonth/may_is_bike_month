# frozen_string_literal: true

require "rails_helper"

RSpec.describe CompetitionTable::UserRow::Component, :js, type: :system do
  let(:preview_path) { "/rails/view_components/competition_table/user_row/component/default" }

  xit "default preview" do
    visit(preview_path)

    expect(page).to have_content "CompetitionTable::UserRow::Component"
  end
end

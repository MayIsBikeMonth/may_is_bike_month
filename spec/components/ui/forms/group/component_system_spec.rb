# frozen_string_literal: true

require "rails_helper"

RSpec.describe UI::Forms::Group::Component, :js, type: :system do
  let(:base_path) { "/rails/view_components/ui/forms/group/component/" }

  # The group labels the input and UI::Forms::Files::Upload's visible button is a label for the same input,
  # so this is what would catch axe's form-field-multiple-labels
  context "file_upload" do
    it "audits clean with the upload control nested in the group" do
      visit("#{base_path}file_upload")

      expect(page).to have_css("label", text: "Avatar")
      expect(page).to have_css("label", text: "Upload")
      expect_axe_clean
    end
  end

  context "content_block" do
    it "focuses the field rendered in the block when the label is clicked" do
      visit("#{base_path}content_block")

      find("label", text: "Email").click

      expect(page).to have_css("#user_email:focus")
    end
  end
end

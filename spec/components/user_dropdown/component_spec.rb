# frozen_string_literal: true

require "rails_helper"

RSpec.describe UserDropdown::Component, type: :component do
  let(:user) { FactoryBot.build_stubbed(:user, display_name: "Rider", strava_info:) }
  let(:strava_info) { nil }
  let(:rendered) { render_inline(described_class.new(current_user: user)) }

  context "with no strava_info" do
    it "renders initials in place of an avatar image" do
      expect(rendered.css("img")).to be_empty
      expect(rendered.text).to include "R"
    end
  end

  context "when profile_medium is the Strava placeholder path" do
    let(:strava_info) { {"profile_medium" => "avatar/athlete/medium.png"} }

    it "renders initials instead of resolving the placeholder as a local asset" do
      expect(rendered.css("img")).to be_empty
    end
  end

  context "when profile_medium is a full url" do
    let(:strava_info) { {"profile_medium" => "https://example.com/profile.jpg"} }

    it "renders the profile image" do
      expect(rendered.css("img").attr("src").value).to eq "https://example.com/profile.jpg"
    end
  end
end

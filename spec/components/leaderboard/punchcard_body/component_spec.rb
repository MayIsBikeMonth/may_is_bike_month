# frozen_string_literal: true

require "rails_helper"

RSpec.describe Leaderboard::PunchcardBody::Component, type: :component do
  let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2025-05-01")) }

  def competition_user_with(display_name:, strava_id:, score:, elevation:)
    user = FactoryBot.create(:user, display_name:, strava_id:)
    cu = FactoryBot.create(:competition_user, user:, competition:)
    cu.update_columns(score_data: {dates: [], distance: 1_000.0, elevation:}, score:)
    cu.reload
  end

  # Passed in score order (rank 1 first), as the wrapper does via score_ordered
  let(:first_place) { competition_user_with(display_name: "First Place", strava_id: "first", score: 9.0, elevation: 1_000.0) }
  let(:second_place) { competition_user_with(display_name: "Second Place", strava_id: "second", score: 5.0, elevation: 800.0) }
  let(:third_place) { competition_user_with(display_name: "Third Place", strava_id: "third", score: 2.0, elevation: 500.0) }
  let(:competition_users) { [first_place, second_place, third_place] }
  let(:rendered) { render_inline(described_class.new(competition:, competition_users:)) }
  let(:badge) { rendered.css('[aria-label*="Elevation leader"]') }

  it "marks the highest-elevation rider who isn't in 1st place" do
    expect(badge.count).to eq 1
    row = badge.first.ancestors.find { |node| node["class"]&.include?("border-b") }
    expect(row.text).to include "Second Place"
  end

  context "when the 1st place rider has less elevation than another rider" do
    let(:first_place) { competition_user_with(display_name: "First Place", strava_id: "first", score: 9.0, elevation: 100.0) }

    it "still awards dessert to the highest-elevation non-1st rider" do
      expect(badge.count).to eq 1
      row = badge.first.ancestors.find { |node| node["class"]&.include?("border-b") }
      expect(row.text).to include "Second Place"
    end
  end

  context "when only the 1st place rider has elevation" do
    let(:second_place) { competition_user_with(display_name: "Second Place", strava_id: "second", score: 5.0, elevation: 0.0) }
    let(:third_place) { competition_user_with(display_name: "Third Place", strava_id: "third", score: 2.0, elevation: 0.0) }

    it "awards dessert to no one" do
      expect(badge.count).to eq 0
    end
  end
end

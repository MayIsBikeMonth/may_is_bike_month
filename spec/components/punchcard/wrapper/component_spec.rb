# frozen_string_literal: true

require "rails_helper"

RSpec.describe Punchcard::Wrapper::Component, type: :component do
  let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2025-05-01")) }

  describe ".level_thresholds" do
    it "derives level 1 by ceiling the competition daily distance requirement in miles" do
      expect(described_class.level_thresholds(competition)).to eq(1 => 3, 2 => 9, 3 => 20, 4 => 40, 5 => 62.14)
    end
  end

  describe ".daily_metrics" do
    let(:competition_user) { FactoryBot.create(:competition_user, competition:) }

    context "with no activities" do
      it "returns an empty-default hash" do
        expect(described_class.daily_metrics(competition_user)["2025-05-01"]).to eq(distance_meters: 0.0, elevation_meters: 0.0)
      end
    end

    context "with activities" do
      let!(:activity) do
        FactoryBot.create(:competition_activity,
          competition_user:,
          distance_meters: 16_093.44,
          elevation_meters: 300,
          start_at: Time.parse("2025-05-03T15:00:00Z"))
      end

      it "sums distance and elevation for each activity date" do
        metrics = described_class.daily_metrics(competition_user)
        expect(metrics["2025-05-03"][:distance_meters]).to be_within(0.01).of(16_093.44)
        expect(metrics["2025-05-03"][:elevation_meters]).to eq 300.0
      end
    end
  end

  describe "render" do
    it "wraps the body in .punchcard-wrap" do
      rendered = render_inline(described_class.new(competition:, competition_users: []))
      expect(rendered.css(".punchcard-wrap")).to be_present
    end
  end
end

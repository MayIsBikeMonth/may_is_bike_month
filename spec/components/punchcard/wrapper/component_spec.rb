# frozen_string_literal: true

require "rails_helper"

RSpec.describe Punchcard::Wrapper::Component, type: :component do
  let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2025-05-01")) }

  describe ".level_thresholds" do
    it "derives level 1 from the competition daily distance requirement in miles" do
      thresholds = described_class.level_thresholds(competition)
      expect(thresholds[1]).to be_within(0.001).of(2.0002)
      expect(thresholds.slice(2, 3, 4, 5)).to eq(2 => 9, 3 => 20, 4 => 40, 5 => 62.14)
    end
  end

  describe ".daily_metrics" do
    let(:competition_user) { FactoryBot.create(:competition_user, competition:) }

    context "with no activities" do
      it "returns an empty-default hash" do
        expect(described_class.daily_metrics(competition_user)["2025-05-01"]).to eq(distance_meters: 0.0, elevation_meters: 0.0, activity_count: 0)
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
      let!(:second_activity) do
        FactoryBot.create(:competition_activity,
          competition_user:,
          distance_meters: 1_000,
          elevation_meters: 50,
          start_at: Time.parse("2025-05-03T20:00:00Z"))
      end

      it "sums distance, elevation, and ride counts for each activity date" do
        metrics = described_class.daily_metrics(competition_user)
        expect(metrics["2025-05-03"][:distance_meters]).to be_within(0.01).of(17_093.44)
        expect(metrics["2025-05-03"][:elevation_meters]).to eq 350.0
        expect(metrics["2025-05-03"][:activity_count]).to eq 2
      end
    end
  end

  describe "render" do
    it "renders the body" do
      rendered = render_inline(described_class.new(competition:, competition_users: []))
      expect(rendered.css("h1").text).to include competition.year.to_s
    end

    context "with non-current competition" do
      it "does not subscribe to a turbo stream" do
        rendered = render_inline(described_class.new(competition:, competition_users: []))
        expect(rendered.css("turbo-cable-stream-source")).to be_empty
      end
    end

    context "with the current competition" do
      let(:competition) { FactoryBot.create(:competition, current: true) }

      it "subscribes to the wrapper turbo stream" do
        rendered = render_inline(described_class.new(competition:, competition_users: []))
        expect(rendered.css("turbo-cable-stream-source").length).to eq 1
        expected_id = ActionView::RecordIdentifier.dom_id(competition, :punchcard_wrapper)
        expect(rendered.css("##{expected_id}")).not_to be_empty
      end
    end
  end

  describe "#broadcast_refresh!" do
    include ActionCable::TestHelper

    let(:competition) { FactoryBot.create(:competition, current: true) }
    let(:component) { described_class.new(competition:, competition_users: []) }
    let(:stream) { "#{competition.to_gid_param}:punchcard_wrapper" }

    it "broadcasts a replace to the wrapper channel" do
      expect { component.broadcast_refresh! }.to have_broadcasted_to(stream)
    end
  end

  describe ".broadcast_refresh_current!" do
    include ActionCable::TestHelper

    context "without a current competition" do
      it "returns nil" do
        expect(described_class.broadcast_refresh_current!).to be_nil
      end
    end

    context "with a current competition" do
      let!(:current_competition) { FactoryBot.create(:competition, current: true) }
      let(:stream) { "#{current_competition.to_gid_param}:punchcard_wrapper" }

      it "broadcasts a replace using the current competition channel" do
        expect { described_class.broadcast_refresh_current! }.to have_broadcasted_to(stream)
      end
    end
  end
end

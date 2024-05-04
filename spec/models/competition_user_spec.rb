require "rails_helper"

RSpec.describe CompetitionUser, type: :model do
  let(:empty_score_hash) { {dates: [], distance: 0, elevation: 0, ids: [], score: 0} }

  def empty_score_data(competition)
    periods = competition.periods.map
    empty_score_hash.except(:ids).merge(periods: periods.map { |prd| prd.merge(empty_score_hash) })
  end

  describe "included_activity_types" do
    let(:competition_user) { FactoryBot.create(:competition_user, included_activity_types:) }
    let(:included_activity_types) { nil }
    it "is default" do
      expect(competition_user).to be_valid
      expect(competition_user.included_activity_types).to eq(["Ride", "Velomobile", "Handcycle"])
    end
    context "specified include_activity_types_string" do
      let(:included_activity_types) { ["Virtual Ride", "Ride ", ""] }
      it "is default" do
        expect(competition_user).to be_valid
        competition_user.reload
        expect(competition_user.included_activity_types).to eq(["Virtual Ride", "Ride"])
      end
    end
  end

  describe "score_data" do
    let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2024-5-1")) }
    let(:competition_user) { FactoryBot.create(:competition_user, competition:) }
    let(:start_at1) { Time.at(1714778082) }
    it "is empty_score_hash" do
      expect(competition_user.calculated_score_data).to eq empty_score_data(competition)
    end

    context "with a competition_activity" do
      let!(:competition_activity1) do
        FactoryBot.create(:competition_activity, competition_user:,
          start_at: start_at1, distance_meters: 10_000, elevation_meters: 200)
      end
      let(:period1_data) do
        {
          start_date: "2024-05-01",
          end_date: "2024-05-05",
          dates: ["2024-05-03"],
          distance: 10_000.00,
          elevation: 200.0,
          ids: [competition_activity1.id],
          score: 1.9999
        }
      end
      let(:activities_for_period) { competition_user.send(:activities_for_period, period1_data.slice(:start_date, :end_date)) }
      it "returns score_hash_for_activities" do
        # validate that it's an active record collection
        expect(activities_for_period.pluck(:id)).to eq([competition_activity1.id])

        calculated_score_data = competition_user.calculated_score_data
        expect(calculated_score_data.except(:periods)).to eq(period1_data.except(:start_date, :end_date, :ids))
        expect(calculated_score_data[:periods].first).to eq period1_data
      end
    end
  end
end

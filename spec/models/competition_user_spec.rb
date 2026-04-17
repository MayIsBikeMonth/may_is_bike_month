require "rails_helper"

RSpec.describe CompetitionUser, type: :model do
  let(:empty_score_hash) { {dates: [], distance: 0, elevation: 0, ids: []} }

  def empty_score_data(competition)
    periods = competition.periods.map
    empty_score_hash.except(:ids).merge(periods: periods.map { |prd| prd.merge(empty_score_hash) })
  end

  describe "included_activity_types" do
    let(:competition_user) { FactoryBot.create(:competition_user, included_activity_types:) }
    let(:included_activity_types) { nil }
    it "is default" do
      expect(competition_user).to be_valid
      expect(competition_user.included_activity_types).to eq(%w[EBikeRide Handcycle Ride Velomobile])
    end
    context "specified include_activity_types_string" do
      let(:included_activity_types) { ["Virtual Ride", "Ride ", ""] }
      it "is default" do
        expect(competition_user).to be_valid
        expect(competition_user.score).to eq 0
        competition_user.reload
        expect(competition_user.included_activity_types).to eq(["Ride", "Virtual Ride"])
      end
    end
  end

  describe "included_dates_strings" do
    let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2024-05-01")) }
    let(:time1) { Time.parse("2024-05-03T02:59:12Z") }
    let!(:competition_activity1) do
      FactoryBot.create(:competition_activity, competition:, start_at: time1,
        distance_meters: competition.daily_distance_requirement / 2)
    end
    let!(:competition_activity2) do
      FactoryBot.create(:competition_activity, competition:, start_at: time1,
        distance_meters: competition.daily_distance_requirement - 300)
    end
    let!(:competition_activity3) do
      FactoryBot.create(:competition_activity, competition:, start_at: time1 + 1.day,
        distance_meters: competition.daily_distance_requirement - 1)
    end
    it "returns the dates that have scores" do
      expect(CompetitionActivity.pluck(:activity_dates_strings).flatten.uniq).to eq(["2024-05-02", "2024-05-03"])
      expect(CompetitionActivity.included_dates_strings).to eq(["2024-05-02"])
    end
  end

  describe "calculated_score_data" do
    let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2024-5-1")) }
    let(:competition_user) { FactoryBot.create(:competition_user, competition:) }
    let(:start_at1) { Time.at(1714778082) }
    it "is empty_score_hash" do
      expect(competition_user.calculated_score_data).to eq empty_score_data(competition).as_json
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
          ids: [competition_activity1.id]
        }.with_indifferent_access
      end
      let(:activities_for_period) { competition_user.send(:activities_for_period, period1_data.slice(:start_date, :end_date)) }

      it "returns score_hash_for_activities" do
        # validate that it's an active record collection
        expect(activities_for_period.pluck(:id)).to eq([competition_activity1.id])

        calculated_score_data = competition_user.calculated_score_data.with_indifferent_access
        expect(calculated_score_data.except(:periods)).to eq(period1_data.except(:start_date, :end_date, :ids))
        expect(calculated_score_data[:periods].first).to eq period1_data
      end
    end
  end

  describe "current_timezone" do
    let(:competition_user) { FactoryBot.create(:competition_user) }

    it "defaults to Pacific time when no activities" do
      expect(competition_user.current_timezone).to eq "America/Los_Angeles"
    end

    context "with activities" do
      let!(:older_activity) do
        FactoryBot.create(:competition_activity, competition_user:,
          start_at: Time.parse("2024-05-01T12:00:00Z"), timezone: "America/Denver")
      end
      let!(:newer_activity) do
        FactoryBot.create(:competition_activity, competition_user:,
          start_at: Time.parse("2024-05-03T12:00:00Z"), timezone: "America/New_York")
      end

      it "uses the timezone from the most recent activity" do
        expect(competition_user.current_timezone).to eq "America/New_York"
      end
    end
  end

  describe "current_date" do
    let(:competition_user) { FactoryBot.create(:competition_user) }

    around { |ex| travel_to(Time.parse("2024-05-04T05:00:00Z")) { ex.run } }

    it "returns today in the default Pacific timezone" do
      # 05:00 UTC is still 2024-05-03 in Pacific
      expect(competition_user.current_date).to eq Date.parse("2024-05-03")
    end

    context "with a most recent activity in a different timezone" do
      let!(:activity) do
        FactoryBot.create(:competition_activity, competition_user:,
          start_at: Time.parse("2024-05-03T12:00:00Z"), timezone: "Australia/Sydney")
      end

      it "returns today in the activity's timezone" do
        # 05:00 UTC on 5/4 is 15:00 on 5/4 in Sydney
        expect(competition_user.current_date).to eq Date.parse("2024-05-04")
      end
    end
  end

  describe "everyday_rider?" do
    let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2024-05-01")) }
    let(:competition_user) { FactoryBot.create(:competition_user, competition:, score_data: {dates:}) }
    let(:dates) { ["2024-05-01", "2024-05-02", "2024-05-03"] }
    let(:now) { Time.parse("2024-05-04T17:00:00Z") }

    around { |ex| travel_to(now) { ex.run } }

    it "is true when every day before current_date has an activity date" do
      # 17:00 UTC on 5/4 is 10:00 PDT on 5/4; days before are 5/1, 5/2, 5/3
      expect(competition_user.current_date).to eq Date.parse("2024-05-04")
      expect(competition_user.everyday_rider?).to be true
    end

    context "when a day before current_date is missing" do
      let(:dates) { ["2024-05-01", "2024-05-03"] }

      it "is false" do
        expect(competition_user.everyday_rider?).to be false
      end
    end

    context "when current_date is the first day of the competition" do
      let(:dates) { [] }
      let(:now) { Time.parse("2024-05-01T17:00:00Z") }

      it "is true vacuously" do
        expect(competition_user.current_date).to eq Date.parse("2024-05-01")
        expect(competition_user.everyday_rider?).to be true
      end
    end

    context "when current_date is after competition end" do
      let(:competition) { FactoryBot.create(:competition, start_date: Date.parse("2024-05-01"), end_date: Date.parse("2024-05-31")) }
      let(:dates) { Competition.dates_strings(Date.parse("2024-05-01"), Date.parse("2024-05-31")) }
      let(:now) { Time.parse("2024-06-15T17:00:00Z") }

      it "only requires coverage through competition end" do
        expect(competition_user.everyday_rider?).to be true
      end
    end
  end

  describe "scoring" do
    let(:competition) { FactoryBot.create(:competition, start_date: Time.parse("2024-05-01")) }
    let(:competition_user1) { FactoryBot.create(:competition_user, competition:) }
    let(:competition_user2) { FactoryBot.create(:competition_user, competition:) }
    let!(:competition_activity1) { FactoryBot.create(:competition_activity, competition_user: competition_user1, distance_meters: 10000) }
    let!(:competition_activity2) { FactoryBot.create(:competition_activity, competition_user: competition_user2, distance_meters: 20000) }
    it "sets the score and orders by the score" do
      competition_user1.reload.update_score_data!
      expect(competition_user1.score_data).to be_present
      competition_user2.reload.update_score_data!
      expect(competition_user2.score_data).to be_present

      expect(competition_user1.score).to be > 1.0
      expect(competition_user2.score).to be > 1.0
      expect(CompetitionUser.score_ordered.pluck(:id)).to eq([competition_user2.id, competition_user1.id])
    end
  end
end

require "rails_helper"

RSpec.describe Competition, type: :model do
  describe "factory" do
    let(:competition) { FactoryBot.create(:competition) }
    it "is valid" do
      expect(competition).to be_valid
    end
  end

  describe "set_current" do
    let(:competition1) { FactoryBot.create(:competition, start_date: Date.parse("2023-5-1"), display_name: nil, current: true) }
    let(:competition2) { FactoryBot.create(:competition, start_date: Time.current - 1.day) }
    it "sets current, unsets all others" do
      expect(competition1.reload.current).to be_truthy
      expect(competition1.display_name).to eq "2023"
      expect(competition2.reload.current).to be_truthy
      expect(competition1.reload.current).to be_falsey
    end
  end

  describe "competition_activities" do
    let(:competition_user) { FactoryBot.create(:competition_user) }
    let(:competition) { competition_user.competition }
    let!(:competition_activity1) { FactoryBot.create(:competition_activity, competition_user:, start_at: competition.start_date.to_time + 3.days) }
    let!(:competition_activity2) { FactoryBot.create(:competition_activity, competition_user:, strava_type: "Run", start_at: competition.start_date.to_time + 4.days) }
    it "has matching activities" do
      expect(competition.reload.competition_activities.pluck(:id)).to match_array([competition_activity1.id])
    end
  end

  describe "invalid_end_date" do
    let(:competition) do
      FactoryBot.build(:competition,
        start_date: Time.current.to_date,
        end_date: (Time.current - 1.week).to_date)
    end
    let(:target_errors) { ["End date must be greater than #{competition.start_date}"] }
    it "is invalid" do
      expect(competition).not_to be_valid
      expect(competition.errors.full_messages).to eq target_errors
    end
  end

  describe "in_period?" do
    let(:competition) { Competition.new(start_date:, end_date:) }
    let(:start_date) { Date.parse("2024-05-01") }
    let(:end_date) { Date.parse("2024-05-31") }

    let(:activity_dates) { [Date.parse("2024-5-1")] }
    it "is truthy" do
      expect(competition.in_period?(activity_dates)).to be_truthy
    end
    context "early" do
      let(:activity_dates) { [Date.parse("2024-4-30"), Date.parse("2024-5-1")] }
      it "is truthy" do
        expect(competition.in_period?(activity_dates)).to be_truthy
      end
    end
    context "late" do
      let(:activity_dates) { [Date.parse("2024-5-30"), Date.parse("2024-6-1")] }
      it "is truthy" do
        expect(competition.in_period?(activity_dates)).to be_truthy
      end
      context "as times" do
        let(:activity_dates) { [Date.parse("2024-5-30").beginning_of_day, Date.parse("2024-6-1").beginning_of_day] }
        it "is truthy" do
          expect(competition.in_period?(activity_dates)).to be_truthy
        end
      end
    end
    context "before" do
      let(:activity_dates) { [Date.parse("2024-4-30")] }
      it "is falsey" do
        expect(competition.in_period?(activity_dates)).to be_falsey
      end
    end
    context "after" do
      let(:activity_dates) { [Date.parse("2025-5-1")] }
      it "is falsey" do
        expect(competition.in_period?(activity_dates)).to be_falsey
      end
    end
    context "none" do
      let(:activity_dates) { [] }
      it "is falsey" do
        expect(competition.in_period?(activity_dates)).to be_falsey
      end
    end
  end

  describe "competition_periods" do
    let(:competition) { FactoryBot.create(:competition, start_date:, end_date:) }
    context "2024" do
      let(:start_date) { Date.parse("2024-5-1") }
      let(:end_date) { nil }
      let(:target_periods) do
        [
          {start_date: "2024-05-01", end_date: "2024-05-05"},
          {start_date: "2024-05-06", end_date: "2024-05-12"},
          {start_date: "2024-05-13", end_date: "2024-05-19"},
          {start_date: "2024-05-20", end_date: "2024-05-26"},
          {start_date: "2024-05-27", end_date: "2024-05-31"}
        ]
      end
      it "returns the target" do
        expect(competition.end_date).to eq Date.parse("2024-5-31")
        expect(competition.periods).to eq target_periods
      end
    end
    # context "2023" do
    #   let(:start_date) { Date.parse("2023-5-1") }
    #   let(:end_date) { Date.parse("2023-5-31") }
    #   let(:target_periods) do
    #     [
    #       {start_date: Date.parse("2023-05-01"), end_date: Date.parse("2023-05-07")},
    #       {start_date: Date.parse("2023-05-08"), end_date: Date.parse("2023-05-14")},
    #       {start_date: Date.parse("2023-05-15"), end_date: Date.parse("2023-05-21")},
    #       {start_date: Date.parse("2023-05-22"), end_date: Date.parse("2023-05-28")},
    #       {start_date: Date.parse("2023-05-29"), end_date: Date.parse("2023-05-31")}
    #     ]
    #   end
    #   it "returns the target" do
    #     expect(competition.periods).to eq target_periods
    #   end
    # end
    # context "2022" do
    #   let(:start_date) { Date.parse("2022-05-01") }
    #   let(:end_date) { Date.parse("2022-05-31") }
    #   let(:target_periods) do
    #     [
    #       {start_date: Date.parse("2022-05-01"), end_date: Date.parse("2022-05-01")},
    #       {start_date: Date.parse("2022-05-02"), end_date: Date.parse("2022-05-08")},
    #       {start_date: Date.parse("2022-05-09"), end_date: Date.parse("2022-05-15")},
    #       {start_date: Date.parse("2022-05-16"), end_date: Date.parse("2022-05-22")},
    #       {start_date: Date.parse("2022-05-23"), end_date: Date.parse("2022-05-29")},
    #       {start_date: Date.parse("2022-05-30"), end_date: Date.parse("2022-05-31")}
    #     ]
    #   end
    #   it "returns the target" do
    #     expect(competition.periods).to eq target_periods
    #   end
    # end
  end

  describe "week_start_from_sunday" do
    # Weeks start on Monday, the same as on Strava
    let(:week_start_from_sunday) { described_class.send(:week_start_from_sunday, date) }
    let(:date) { Date.parse("2024-5-12") }
    it "returns week start" do
      expect(week_start_from_sunday).to eq Date.parse("2024-5-6")
    end
    context "beginning of month" do
      let(:date) { Date.parse("2024-5-3") }
      it "returns week start" do
        expect(week_start_from_sunday).to eq Date.parse("2024-5-1")
      end
    end
  end
end

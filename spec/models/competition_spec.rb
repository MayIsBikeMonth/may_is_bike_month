require "rails_helper"

RSpec.describe Competition, type: :model do
  describe "factory" do
    let(:competition) { FactoryBot.create(:competition) }
    it "is valid" do
      expect(competition).to be_valid
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
end

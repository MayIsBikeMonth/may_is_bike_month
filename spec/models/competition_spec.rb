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
end

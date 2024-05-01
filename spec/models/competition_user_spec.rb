require "rails_helper"

RSpec.describe CompetitionUser, type: :model do
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
end

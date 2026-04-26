require "rails_helper"

RSpec.describe CreateCompetitionUsersJob, type: :job do
  let(:instance) { described_class.new }

  describe "perform" do
    let(:competition) { FactoryBot.create(:competition) }
    let!(:user1) { FactoryBot.create(:user) }
    let!(:user2) { FactoryBot.create(:user) }

    it "creates a CompetitionUser for every user" do
      expect { instance.perform(competition.id) }.to change(CompetitionUser, :count).by(2)
      expect(competition.competition_users.pluck(:user_id)).to match_array([user1.id, user2.id])
      expect(competition.competition_users.pluck(:included_in_competition).uniq).to eq([false])
    end

    context "when run again" do
      before { instance.perform(competition.id) }

      it "does not create duplicates" do
        expect { instance.perform(competition.id) }.not_to change(CompetitionUser, :count)
      end
    end
  end
end

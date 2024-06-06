require "rails_helper"

RSpec.describe UpdateCompetitionUserJob, type: :job do
  let(:instance) { described_class.new }

  describe "enqueue_current" do
    let!(:competition_older) { FactoryBot.create(:competition, start_date: Date.parse("2024-1-1")) }
    let!(:competition) { FactoryBot.create(:competition, current: true) }
    let!(:competition_user) { FactoryBot.create(:competition_user, competition:) }
    let!(:competition_user_excluded) { FactoryBot.create(:competition_user, included_in_competition: false, competition:) }
    let!(:competition_user_older_competition) { FactoryBot.create(:competition_user, competition: competition_older) }
    before { Sidekiq::Worker.clear_all }

    it "enqueues the current user" do
      expect(UpdateCompetitionUserJob.jobs.count).to eq 0
      described_class.enqueue_current
      expect(UpdateCompetitionUserJob.jobs.map { |j| j["args"] }.flatten).to eq([competition_user.id])
    end
  end

  describe "perform" do
    let(:user) { FactoryBot.create(:user_with_strava_token) }
    let(:competition) { FactoryBot.create(:competition, start_date: Time.parse("2024-05-01")) }
    let(:competition_user) { FactoryBot.create(:competition_user, user:, competition:) }

    it "updates user score" do
      expect(competition.start_date).to eq Date.parse("2024-5-1")
      expect(competition_user.score_data).to be_blank
      expect(competition_user.score).to eq 0
      VCR.use_cassette("update_competition_user_job", match_requests_on: [:path]) do
        instance.perform(competition_user.id)
      end
      expect(competition_user.reload.score_data).to be_present
      expect(competition_user.competition_activities.count).to eq 3
      expect(competition_user.score).to be > 3
      expect(competition_user.score).to be < 4

      expect { described_class.enqueue_current }.not_to change(described_class.jobs, :count)
    end

    context "data exists" do
      let(:time) { Time.current - 5.minutes }
      it "doesn't update" do
        expect(competition_user.score).to eq 0
        VCR.use_cassette("update_competition_user_job", match_requests_on: [:path]) do
          instance.perform(competition_user.id)
        end
        competition_user.reload.update_column(:updated_at, time)

        VCR.use_cassette("update_competition_user_job", match_requests_on: [:path]) do
          instance.perform(competition_user.id)
        end
        expect(competition_user.reload.updated_at).to be_within(1).of(time)
      end
    end

    context "data changes slightly" do
      let(:time) { Time.current - 5.minutes }
      it "doesn't update" do
        expect(competition_user.score).to eq 0
        VCR.use_cassette("update_competition_user_job", match_requests_on: [:path]) do
          instance.perform(competition_user.id)
        end
        competition_user.reload.update_columns(updated_at: time, score: 0)

        VCR.use_cassette("update_competition_user_job", match_requests_on: [:path]) do
          instance.perform(competition_user.id)
        end
        expect(competition_user.reload.updated_at).to be_within(1).of(Time.current)
        expect(competition_user.score).to be > 3
      end
    end
  end
end

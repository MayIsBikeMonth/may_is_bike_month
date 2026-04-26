require "rails_helper"

RSpec.describe UpdateCompetitionUserJob, type: :job do
  let(:instance) { described_class.new }

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
    end

    context "user without strava auth" do
      let(:user) { FactoryBot.create(:user) }

      it "returns early without hitting strava" do
        competition_user.update!(score_data: {dates: [], distance: 500, elevation: 10})
        instance.perform(competition_user.id)
        expect(competition_user.reload.competition_activities.count).to eq 0
        expect(competition_user.score_data["distance"]).to eq 500
      end
    end

    context "with a current competition" do
      include ActionCable::TestHelper

      let(:competition) { FactoryBot.create(:competition, start_date: Time.parse("2024-05-01"), current: true) }
      let(:stream) { "#{competition.to_gid_param}:punchcard_wrapper" }

      it "broadcasts a punchcard refresh" do
        VCR.use_cassette("update_competition_user_job", match_requests_on: [:path]) do
          expect { instance.perform(competition_user.id) }.to have_broadcasted_to(stream)
        end
      end
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

    context "legacy competition" do
      let(:competition) do
        FactoryBot.create(:competition, kind: :legacy,
          start_date: Date.parse("2024-05-01"), end_date: Date.parse("2024-05-31"))
      end
      let(:imported_score_data) do
        {dates: [], distance: 1_000_000, elevation: 5_000,
         periods: competition.periods.map { |p| p.merge(distance: 200_000, elevation: 1_000) }}.as_json
      end

      before { competition_user.update!(score_data: imported_score_data) }

      it "imports activities without overwriting the imported score data" do
        VCR.use_cassette("update_competition_user_job", match_requests_on: [:path]) do
          instance.perform(competition_user.id)
        end
        expect(competition_user.reload.competition_activities.count).to eq 3
        expect(competition_user.score_data).to eq imported_score_data
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

require "rails_helper"

RSpec.describe ProcessStravaWebhookJob, type: :job do
  let(:instance) { described_class.new }
  let(:user) { FactoryBot.create(:user_with_strava_token) }
  let(:competition) { FactoryBot.create(:competition, start_date: Time.current.beginning_of_month.to_date) }
  let!(:competition_user) { FactoryBot.create(:competition_user, user:, competition:) }

  def build_request(parameters)
    StravaRequest.create!(user:, kind: :incoming_webhook, parameters: parameters.as_json)
  end

  describe "perform" do
    before { Sidekiq::Job.clear_all }

    context "activity create" do
      let(:strava_request) do
        build_request(object_type: "activity", aspect_type: "create",
          object_id: 123, owner_id: user.strava_id.to_i)
      end

      it "enqueues UpdateCompetitionUserJob for the current competition_user" do
        expect { instance.perform(strava_request.id) }
          .to change(UpdateCompetitionUserJob.jobs, :count).by(1)
        expect(UpdateCompetitionUserJob.jobs.last["args"]).to eq [competition_user.id]
      end
    end

    context "activity update" do
      let(:strava_request) do
        build_request(object_type: "activity", aspect_type: "update",
          object_id: 123, owner_id: user.strava_id.to_i,
          updates: {title: "new name"})
      end

      it "enqueues UpdateCompetitionUserJob" do
        expect { instance.perform(strava_request.id) }
          .to change(UpdateCompetitionUserJob.jobs, :count).by(1)
      end
    end

    context "activity delete" do
      let!(:competition_activity) do
        FactoryBot.create(:competition_activity, competition_user:, strava_id: "123")
      end
      let!(:other_activity) do
        FactoryBot.create(:competition_activity, competition_user:, strava_id: "999")
      end
      let(:strava_request) do
        build_request(object_type: "activity", aspect_type: "delete",
          object_id: 123, owner_id: user.strava_id.to_i)
      end

      it "destroys the matching activity and leaves others" do
        expect { instance.perform(strava_request.id) }
          .to change(CompetitionActivity, :count).by(-1)
        expect(CompetitionActivity.find_by(id: competition_activity.id)).to be_nil
        expect(CompetitionActivity.find_by(id: other_activity.id)).to be_present
        expect(UpdateCompetitionUserJob.jobs.count).to eq 0
      end

      context "activity belongs to a different user" do
        let(:other_user) { FactoryBot.create(:user) }
        let(:other_competition_user) { FactoryBot.create(:competition_user, user: other_user, competition:) }
        let!(:competition_activity) do
          FactoryBot.create(:competition_activity, competition_user: other_competition_user, strava_id: "123")
        end

        it "does not destroy activities from other users" do
          expect { instance.perform(strava_request.id) }.not_to change(CompetitionActivity, :count)
        end
      end
    end

    context "athlete deauthorization" do
      let(:strava_request) do
        build_request(object_type: "athlete", aspect_type: "update",
          object_id: user.strava_id.to_i, owner_id: user.strava_id.to_i,
          updates: {authorized: "false"})
      end

      it "clears the user's strava_auth" do
        expect(user.reload.strava_auth).to be_present
        instance.perform(strava_request.id)
        expect(user.reload.strava_auth).to eq({})
      end
    end

    context "athlete update (not deauthorization)" do
      let(:strava_request) do
        build_request(object_type: "athlete", aspect_type: "update",
          object_id: user.strava_id.to_i, owner_id: user.strava_id.to_i,
          updates: {weight: 80})
      end

      it "does not clear strava_auth" do
        original_auth = user.strava_auth
        instance.perform(strava_request.id)
        expect(user.reload.strava_auth).to eq(original_auth)
      end
    end
  end
end

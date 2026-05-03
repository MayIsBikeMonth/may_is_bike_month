require "rails_helper"

base_url = "/admin/competition_activities"
RSpec.describe base_url, type: :request do
  describe "index" do
    it "sets return to" do
      get base_url
      expect(response).to redirect_to root_url
      expect(session[:user_return_to]).to eq base_url
    end

    context "signed in" do
      include_context :logged_in_as_user
      it "flash errors" do
        get base_url
        expect(response).to redirect_to root_url
        expect(flash[:error]).to be_present
      end
    end
  end

  context "signed in as admin" do
    include_context :logged_in_as_admin

    describe "index" do
      it "renders" do
        get base_url
        expect(response.code).to eq "200"
        expect(response).to render_template("admin/competition_activities/index")
      end

      context "with activities across competitions" do
        let(:competition1) { FactoryBot.create(:competition, start_date: Date.parse("2024-05-01")) }
        let(:competition2) { FactoryBot.create(:competition) }
        let(:competition_user1) { FactoryBot.create(:competition_user, competition: competition1) }
        let(:competition_user2) { FactoryBot.create(:competition_user, competition: competition2) }
        let!(:activity1) { FactoryBot.create(:competition_activity, competition_user: competition_user1) }
        let!(:activity2) { FactoryBot.create(:competition_activity, competition_user: competition_user2) }

        it "defaults to the current competition" do
          expect(Competition.current).to eq competition2

          get base_url
          expect(response.code).to eq "200"
          expect(assigns(:competition_subject)).to eq competition2
          expect(assigns(:competition_activities).pluck(:id)).to eq([activity2.id])
        end

        it "filters by search_competition_id" do
          get "#{base_url}?search_competition_id=#{competition1.id}"
          expect(response.code).to eq "200"
          expect(assigns(:competition_subject)).to eq competition1
          expect(assigns(:competition_activities).pluck(:id)).to eq([activity1.id])
        end

        it "shows all competitions when search_competition_id=all" do
          get "#{base_url}?search_competition_id=all"
          expect(response.code).to eq "200"
          expect(assigns(:competition_subject)).to be_nil
          expect(assigns(:competition_activities).pluck(:id)).to match_array([activity1.id, activity2.id])
        end

        it "filters by search_competition_user_id" do
          get "#{base_url}?search_competition_user_id=#{competition_user1.id}"
          expect(response.code).to eq "200"
          expect(assigns(:competition_user_subject)).to eq competition_user1
          expect(assigns(:competition_subject)).to eq competition1
          expect(assigns(:competition_activities).pluck(:id)).to eq([activity1.id])
        end

        it "filters by user" do
          get "#{base_url}?search_competition_id=all&user=#{competition_user1.user.slug}"
          expect(response.code).to eq "200"
          expect(assigns(:user_subject)).to eq competition_user1.user
          expect(assigns(:competition_activities).pluck(:id)).to eq([activity1.id])
        end
      end

      describe "show_exclusion_reason toggle" do
        it "is off by default and toggle link points to true" do
          get base_url
          expect(response.body).to include("search_show_exclusion_reason=true")
          expect(response.body).not_to include("Exclusion reason")
        end

        it "is on with search_show_exclusion_reason=true" do
          get "#{base_url}?search_show_exclusion_reason=true"
          expect(response.body).to include("search_show_exclusion_reason=false")
          expect(response.body).to include("Exclusion reason")
        end
      end
    end
  end
end

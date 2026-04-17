require "rails_helper"

base_url = "/admin/strava_requests"
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
        expect(response).to render_template("admin/strava_requests/index")
      end

      context "with strava_requests" do
        let!(:strava_request1) { FactoryBot.create(:strava_request) }
        let!(:strava_request2) { FactoryBot.create(:strava_request, status: 401, error_response: {"message" => "nope"}) }

        it "renders" do
          get base_url
          expect(response.code).to eq "200"
          expect(assigns(:strava_requests).pluck(:id)).to match_array([strava_request1.id, strava_request2.id])
        end

        context "filtered by user" do
          it "renders" do
            get "#{base_url}?user=#{strava_request1.user.display_name}"
            expect(response.code).to eq "200"
            expect(assigns(:user_subject)&.id).to eq strava_request1.user.id
            expect(assigns(:strava_requests).pluck(:id)).to eq([strava_request1.id])
          end
        end
      end
    end
  end
end
